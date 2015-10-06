//
//  CustomScrollView.h
//  CustomScrollView
//
//  Created by Ole Begemann on 16.04.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol CustomScrollViewDelegate <NSObject>

- (BOOL)panGestureDidChange:(UIPanGestureRecognizer *)panGestureRecognizer;

@end


@interface CustomScrollView : UIView

@property (weak, nonatomic) id<CustomScrollViewDelegate> delegate;

@property (nonatomic) CGSize contentSize;

@property (nonatomic, readonly) CGPoint contentOffset;

@end
