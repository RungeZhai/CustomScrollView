//
//  ViewController.m
//  UIScrollViewTest
//
//  Created by liuge on 9/19/15.
//  Copyright (c) 2015 ZiXuWuYou. All rights reserved.
//

#import "ViewController.h"
#import "CustomScrollView.h"

@interface ViewController ()<CustomScrollViewDelegate> {
    CGFloat _originalTopViewHeight;
    CGFloat _shrunkenTopViewHeight;
    CGFloat _originalLabelHeight;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewHeight;

@property (weak, nonatomic) IBOutlet UILabel *label;

@property (weak, nonatomic) IBOutlet CustomScrollView *customScrollView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _customScrollView.delegate = self;
    _customScrollView.clipsToBounds = YES;
    
    CGFloat contentHeight = 410, labelHeight = 40;
    
    _customScrollView.contentSize = CGSizeMake(self.view.bounds.size.width, contentHeight);
    
    UILabel *topLabel = [[UILabel alloc] initWithFrame:(CGRect){0, 0, self.view.bounds.size.width, labelHeight}];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = @"ScrollView's content begins here";
    [_customScrollView addSubview:topLabel];
    
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:(CGRect){0, contentHeight - labelHeight, self.view.bounds.size.width, labelHeight}];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"ScrollView's content ends here";
    [_customScrollView addSubview:bottomLabel];
    
    labelHeight *= 4;
    UILabel *centerLabel = [[UILabel alloc] initWithFrame:(CGRect){0, (contentHeight - labelHeight) / 2, self.view.bounds.size.width, labelHeight}];
    centerLabel.text = @"This is scrollView's content0\nThis is scrollView's content1\nThis is scrollView's content2\nThis is scrollView's content3";
    centerLabel.textAlignment = NSTextAlignmentCenter;
    centerLabel.numberOfLines = 0;
    [_customScrollView addSubview:centerLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_originalLabelHeight) {
        _originalTopViewHeight = _topViewHeight.constant;
        _shrunkenTopViewHeight = ceil(_originalTopViewHeight / 1.23);
        _originalLabelHeight = _label.frame.size.height;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setTopViewHeightWithFloat:_shrunkenTopViewHeight];
}


#pragma mark - CustomScrollViewDelegate

- (BOOL)panGestureDidChange:(UIPanGestureRecognizer *)panGestureRecognizer {
    
    static CGFloat translationYBeforeRecognition = 0;
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            translationYBeforeRecognition = 0;
            
            // fall through
            
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [panGestureRecognizer translationInView:_customScrollView];
            CGFloat translationY = translation.y - translationYBeforeRecognition;
            
            CGFloat scrollViewContentOffsetY = _customScrollView.contentOffset.y;
            BOOL topViewShrunken = _topViewHeight.constant < _originalTopViewHeight;
            BOOL topViewShrinkable = _topViewHeight.constant > _shrunkenTopViewHeight;
            
            if (translationY >= 0) {
                if (scrollViewContentOffsetY <= 0 && topViewShrunken) {
                    
                    [self setTopViewHeightWithFloat:_topViewHeight.constant + translationY];
                    
                    [panGestureRecognizer setTranslation:CGPointZero inView:_customScrollView];
                    translationYBeforeRecognition = 0;
                    return YES;
                }
                
            } else if (translationY < 0) {
                if (topViewShrinkable) {
                    
                    [self setTopViewHeightWithFloat:_topViewHeight.constant + translationY];
                    
                    [panGestureRecognizer setTranslation:CGPointZero inView:_customScrollView];
                    translationYBeforeRecognition = 0;
                    return YES;
                }
            }
            
            translationYBeforeRecognition = translation.y;
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            break;
            
        default:
            break;
    }
    
    return NO;
}

- (void)setTopViewHeightWithFloat:(CGFloat)topViewHeight {
    topViewHeight = MIN(MAX(topViewHeight, _shrunkenTopViewHeight), _originalTopViewHeight);
    
    _topViewHeight.constant = topViewHeight;
    
    CGFloat shrunkenLabelHeight = _originalLabelHeight - (_originalTopViewHeight - topViewHeight);
    CGFloat scale = shrunkenLabelHeight / _originalLabelHeight;
    _label.transform = CGAffineTransformMakeScale(scale, scale);
    
    [self.view layoutSubviews];
}

@end
