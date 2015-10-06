//
//  CustomScrollView.m
//  CustomScrollView
//
//  Created by Ole Begemann on 16.04.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//  Parts of the class are based on https://github.com/grp/CustomScrollView/blob/custom-scroll-with-pop/CustomScrollView/CustomScrollView.m

#import "CustomScrollView.h"
#import "CSCDynamicItem.h"

static CGFloat rubberBandDistance(CGFloat offset, CGFloat dimension) {

    const CGFloat constant = 0.55f;
    CGFloat result = (constant * fabs(offset) * dimension) / (dimension + constant * fabs(offset));
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0f ? -result : result;
}

@interface CustomScrollView ()
@property CGRect startBounds;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, weak) UIDynamicItemBehavior *decelerationBehavior;
@property (nonatomic, weak) UIAttachmentBehavior *springBehavior;
@property (nonatomic, strong) CSCDynamicItem *dynamicItem;
@end

@implementation CustomScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }
    
    [self commonInitForCustomScrollView];
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self == nil) {
        return nil;
    }
    
    [self commonInitForCustomScrollView];
    return self;
}

- (void)commonInitForCustomScrollView
{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:panGestureRecognizer];

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    self.dynamicItem = [[CSCDynamicItem alloc] init];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.startBounds = self.bounds;
            [self.animator removeAllBehaviors];
        }
            // fall through

        case UIGestureRecognizerStateChanged:
        {
            if ([self.delegate respondsToSelector:@selector(panGestureDidChange:)]) {
                if ([self.delegate panGestureDidChange:panGestureRecognizer]) {
                    self.startBounds = self.bounds;
                    break;
                }
            }
            
            CGPoint translation = [panGestureRecognizer translationInView:self];
            
            CGRect bounds = self.startBounds;

            if (!self.scrollHorizontal) {
                translation.x = 0.0;
            }
            if (!self.scrollVertical) {
                translation.y = 0.0;
            }

            CGFloat newBoundsOriginX = bounds.origin.x - translation.x;
            CGFloat minBoundsOriginX = 0.0;
            CGFloat maxBoundsOriginX = self.contentSize.width - bounds.size.width;
            CGFloat constrainedBoundsOriginX = fmax(minBoundsOriginX, fmin(newBoundsOriginX, maxBoundsOriginX));
            CGFloat rubberBandedX = rubberBandDistance(newBoundsOriginX - constrainedBoundsOriginX, CGRectGetWidth(self.bounds));
            bounds.origin.x = constrainedBoundsOriginX + rubberBandedX;

            CGFloat newBoundsOriginY = bounds.origin.y - translation.y;
            CGFloat minBoundsOriginY = 0.0;
            CGFloat maxBoundsOriginY = self.contentSize.height - bounds.size.height;
            CGFloat constrainedBoundsOriginY = fmax(minBoundsOriginY, fmin(newBoundsOriginY, maxBoundsOriginY));
            CGFloat rubberBandedY = rubberBandDistance(newBoundsOriginY - constrainedBoundsOriginY, CGRectGetHeight(self.bounds));
            bounds.origin.y = constrainedBoundsOriginY + rubberBandedY;

            self.bounds = bounds;
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            CGPoint velocity = [panGestureRecognizer velocityInView:self];
            
            if (![self scrollHorizontal]) {
                velocity.x = 0;
            }
            if (![self scrollVertical]) {
                velocity.y = 0;
            }
            velocity.x = -velocity.x;
            velocity.y = -velocity.y;

            self.dynamicItem.center = self.bounds.origin;
            UIDynamicItemBehavior *decelerationBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.dynamicItem]];
            [decelerationBehavior addLinearVelocity:velocity forItem:self.dynamicItem];
            decelerationBehavior.resistance = 2.0;

            __weak typeof(self)weakSelf = self;
            decelerationBehavior.action = ^{
                // IMPORTANT: If the deceleration behavior is removed, the bounds' origin will stop updating. See other possible ways of updating origin in the accompanying blog post.
                CGRect bounds = weakSelf.bounds;
                bounds.origin = weakSelf.dynamicItem.center;
                weakSelf.bounds = bounds;
            };

            [self.animator addBehavior:decelerationBehavior];
            self.decelerationBehavior = decelerationBehavior;
        }
            break;

        default:
            break;
    }
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    CGPoint maxBoundsOrigin = CGPointMake(self.contentSize.width - bounds.size.width,
                                    self.contentSize.height - bounds.size.height);
    BOOL outsideBoundsMinimum = bounds.origin.x < 0.0 || bounds.origin.y < 0.0;
    BOOL outsideBoundsMaximum = bounds.origin.x > maxBoundsOrigin.x || bounds.origin.y > maxBoundsOrigin.y;

    // make it non-reenterable
    if ((outsideBoundsMaximum || outsideBoundsMinimum) &&
        (self.decelerationBehavior && !self.springBehavior)) {

        CGPoint target = bounds.origin;
        if (outsideBoundsMinimum) {
            target.x = fmin(maxBoundsOrigin.x, fmax(target.x, 0.0));
            target.y = fmin(maxBoundsOrigin.y, fmax(target.y, 0.0));
        } else if (outsideBoundsMaximum) {
            // `fmax` is used to fix the case when contentSize is smaller than bounds
            target.x = fmax(0, fmin(target.x, maxBoundsOrigin.x));
            target.y = fmax(0, fmin(target.y, maxBoundsOrigin.y));
        }

        UIAttachmentBehavior *springBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.dynamicItem attachedToAnchor:target];
        // Has to be equal to zero, because otherwise the bounds.origin wouldn't exactly match the target's position.
        springBehavior.length = 0;
        // These two values were chosen by trial and error.
        springBehavior.damping = 1;
        springBehavior.frequency = 2;

        [self.animator addBehavior:springBehavior];
        self.springBehavior = springBehavior;
    }
}

- (BOOL)scrollVertical
{
    return self.contentSize.height > CGRectGetHeight(self.bounds);
}

- (BOOL)scrollHorizontal
{
    return self.contentSize.width > CGRectGetWidth(self.bounds);
}

- (CGPoint)contentOffset {
    return self.bounds.origin;
}

@end
