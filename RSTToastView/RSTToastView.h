//
//  RSTToastView.h
//  GBA4iOS
//
//  Created by Riley Testut on 11/28/13.
//  Copyright (c) 2013 Riley Testut. All rights reserved.
//

@import UIKit;

extern const CGFloat RSTToastViewCornerRadiusAutomaticRoundedDimension;

extern const CGFloat RSTToastViewAutomaticWidth;
extern const CGFloat RSTToastViewMaximumWidth;

extern NSString *const RSTToastViewWillShowNotification;
extern NSString *const RSTToastViewDidShowNotification;
extern NSString *const RSTToastViewWillHideNotification;
extern NSString *const RSTToastViewDidHideNotification;

extern NSString *const RSTToastViewWasTappedNotification;


@class RSTToastView;


@protocol RSTToastViewDelegate <NSObject>

@optional
- (void)toastViewWillShow:(RSTToastView *)toastView;
- (void)toastViewDidShow:(RSTToastView *)toastView;
- (void)toastViewWillHide:(RSTToastView *)toastView;
- (void)toastViewDidHide:(RSTToastView *)toastView;

@end


@interface RSTToastView : UIControl

@property (weak, nonatomic) id<RSTToastViewDelegate> delegate;

// Content
@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) BOOL showsActivityIndicator;

// Interactions
@property (nonatomic, assign, getter = isInteractive) BOOL interactive;

// State
@property (nonatomic, assign, readonly, getter = isVisible) BOOL visible;

// Customizability
@property (nonatomic, copy) UIColor *tintColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, copy) UIFont *font UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) CGFloat alpha UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) UIRectEdge presentationEdge UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) UIRectEdge alignmentEdge UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CGFloat edgeSpacing UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) CGFloat width UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSInteger numberOfLines;

// Class Methods
+ (void)show NS_EXTENSION_UNAVAILABLE_IOS("Please specify a view to be shown in.");

+ (void)showWithMessage:(NSString *)message NS_EXTENSION_UNAVAILABLE_IOS("Please specify a view to be shown in.");
+ (void)showWithMessage:(NSString *)message duration:(NSTimeInterval)duration NS_EXTENSION_UNAVAILABLE_IOS("Please specify a view to be shown in.");

+ (void)showWithMessage:(NSString *)message inView:(UIView *)view;
+ (void)showWithMessage:(NSString *)message inView:(UIView *)view duration:(NSTimeInterval)duration;

+ (void)showWithActivityMessage:(NSString *)message NS_EXTENSION_UNAVAILABLE_IOS("Please specify a view to be shown in.");
+ (void)showWithActivityMessage:(NSString *)message duration:(NSTimeInterval)duration NS_EXTENSION_UNAVAILABLE_IOS("Please specify a view to be shown in.");

+ (void)showWithActivityMessage:(NSString *)message inView:(UIView *)view;
+ (void)showWithActivityMessage:(NSString *)message inView:(UIView *)view duration:(NSTimeInterval)duration;

+ (void)updateWithMessage:(NSString *)message;
+ (void)updateWithActivityMessage:(NSString *)message;

+ (void)hide;

// Instance Methods
- (instancetype)initWithMessage:(NSString *)message;
+ (instancetype)toastViewWithMessage:(NSString *)message;

- (void)show NS_EXTENSION_UNAVAILABLE_IOS("Please specify a view to be shown in.");
- (void)showForDuration:(NSTimeInterval)duration NS_EXTENSION_UNAVAILABLE_IOS("Please specify a view to be shown in.");

- (void)showInView:(UIView *)view;
- (void)showInView:(UIView *)view duration:(NSTimeInterval)duration;

- (void)hide;

@end
