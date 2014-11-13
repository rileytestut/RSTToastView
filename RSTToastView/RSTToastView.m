//
//  RSTToastView.m
//  GBA4iOS
//
//  Created by Riley Testut on 11/28/13.
//  Copyright (c) 2013 Riley Testut. All rights reserved.
//

#import "RSTToastView.h"

#ifndef RST_APP_EXTENSION

@interface RSTPresentationRootViewController : UIViewController

@end

@implementation RSTPresentationRootViewController

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    // Listen to UIApplicationWillChangeStatusBarOrientationNotification to know when the app's top view controller rotates
    return UIInterfaceOrientationMaskAll;
}

@end


@interface RSTPresentationWindow : UIWindow

@end

@implementation RSTPresentationWindow

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self)
    {
        RSTPresentationRootViewController *rootViewController = [RSTPresentationRootViewController new];
        rootViewController.view.frame = frame;
        rootViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.rootViewController = rootViewController;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceOrientationWillChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
        
        [self rotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation fromInterfaceOrientation:UIInterfaceOrientationPortrait animated:NO];
        
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}

#pragma mark - Rotation

- (void)interfaceOrientationWillChange:(NSNotification *)notification
{
    UIInterfaceOrientation interfaceOrientation = [notification.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    UIInterfaceOrientation previousInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    [self rotateToInterfaceOrientation:interfaceOrientation fromInterfaceOrientation:previousInterfaceOrientation animated:YES];
}

- (void)rotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation fromInterfaceOrientation:(UIInterfaceOrientation)previousInterfaceOrientation animated:(BOOL)animated
{
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(fixedCoordinateSpace)])
    {
        bounds = [[UIScreen mainScreen].fixedCoordinateSpace convertRect:[UIScreen mainScreen].bounds fromCoordinateSpace:[UIScreen mainScreen].coordinateSpace];
    }
    
    CGFloat animationDuration = [[UIApplication sharedApplication] statusBarOrientationAnimationDuration];
    
    if (interfaceOrientation != UIInterfaceOrientationUnknown)
    {
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation) == UIInterfaceOrientationIsPortrait(previousInterfaceOrientation))
        {
            animationDuration *= 2.0f;
        }
        
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
        {
            bounds = CGRectMake(0, 0, CGRectGetHeight(bounds), CGRectGetWidth(bounds));
        }
    }
    
    CGAffineTransform rotationTransform = CGAffineTransformIdentity;
    
    switch (interfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            rotationTransform = CGAffineTransformMakeRotation(0.0);
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            rotationTransform = CGAffineTransformMakeRotation(M_PI);
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            rotationTransform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
            break;
            
        default:
            break;
    }

    if (animated)
    {
        
        [UIView animateWithDuration:animationDuration animations:^{
            self.transform = rotationTransform;
            self.bounds = bounds;
            
            self.frame = ({
                CGRect frame = self.frame;
                frame.origin.x = 0;
                frame.origin.y = 0;
                frame;
            });
        }];
    }
    else
    {
        self.transform = rotationTransform;
        self.bounds = bounds;
        
        self.frame = ({
            CGRect frame = self.frame;
            frame.origin.x = 0;
            frame.origin.y = 0;
            frame;
        });
    }
    
}

#pragma mark - Hit Test

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    
    if (view == self || view == self.rootViewController.view)
    {
        return nil;
    }
    
    return view;
}


@end

#endif

const CGFloat RSTToastViewCornerRadiusAutomaticRoundedDimension = -1816.1816;
const CGFloat RSTToastViewAutomaticWidth = 0;
const CGFloat RSTToastViewMaximumWidth = -1816.1816;

NSString *const RSTToastViewWillShowNotification = @"RSTToastViewWillShowNotification";
NSString *const RSTToastViewDidShowNotification = @"RSTToastViewDidShowNotification";
NSString *const RSTToastViewWillHideNotification = @"RSTToastViewWillHideNotification";
NSString *const RSTToastViewDidHideNotification = @"RSTToastViewDidHideNotification";

NSString *const RSTToastViewWasTappedNotification = @"RSTToastViewWasTappedNotification";

static RSTToastView *_globalToastView;

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface RSTToastView ()

@property (nonatomic, readwrite, assign, getter = isVisible) BOOL visible;

@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) CALayer *borderLayer;
@property (nonatomic, strong) NSTimer *hidingTimer;

@property (nonatomic, assign) UIRectEdge currentPresentationEdge;
@property (nonatomic, assign) UIRectEdge currentAlignmentEdge;
@property (nonatomic, assign) BOOL presentAfterHiding;
@property (nonatomic, weak) UIView *presentationView; // Need to keep reference even after it is removed from superview

@property (nonatomic, assign, getter=isBeingHidden) BOOL beingHidden;

@end

@implementation RSTToastView

#pragma mark - UIAppearance

+ (void)load
{
    UIColor *gba4iosPurpleColor = [UIColor colorWithRed:120.0/255.0 green:32.0/255.0 blue:157.0/255.0 alpha:1.0];
    [[RSTToastView appearance] setTintColor:gba4iosPurpleColor];
}

#pragma mark - Life Cycle

- (instancetype)initWithMessage:(NSString *)message
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        // General
        
        self.clipsToBounds = YES;
        self.layer.allowsGroupOpacity = YES;
        
        // Private Properties
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _messageLabel.textColor = [UIColor whiteColor];
        _messageLabel.minimumScaleFactor = 0.75;
        _messageLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_messageLabel];
        
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:_activityIndicatorView];
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rst_toastViewWasTapped:)];
        [self addGestureRecognizer:_tapGestureRecognizer];
        
        // Public
        self.showsActivityIndicator = NO;
        
        // Can't set through setter directly (http://petersteinberger.com/blog/2013/uiappearance-for-custom-views/ )
        // self.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        
        self.messageLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        self.messageLabel.text = message;
        
        _cornerRadius = 10.0f;
        
        self.presentationEdge = UIRectEdgeBottom;
        self.alignmentEdge = UIRectEdgeNone;
        
        _edgeSpacing = 10.0f;
        
        _width = RSTToastViewAutomaticWidth;
        
        // Motion Effects
        UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xAxis.minimumRelativeValue = @(-10);
        xAxis.maximumRelativeValue = @(10);
        
        UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yAxis.minimumRelativeValue = @(-10);
        yAxis.maximumRelativeValue = @(10);
        
        UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
        group.motionEffects = @[xAxis, yAxis];
        [self addMotionEffect:group];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rst_willShowToastView:) name:RSTToastViewWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rst_didHideToastView:) name:RSTToastViewDidHideNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rst_willChangeStatusBarOrientation:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

+ (instancetype)toastViewWithMessage:(NSString *)message
{
    return [[RSTToastView alloc] initWithMessage:message];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Presentation

+ (void)show
{
    [_globalToastView show];
}

+ (void)showWithMessage:(NSString *)message
{
    [RSTToastView showWithMessage:message duration:0];
}

+ (void)showWithMessage:(NSString *)message duration:(NSTimeInterval)duration
{
    [RSTToastView showWithMessage:message inView:[RSTToastView presentationWindow] duration:duration];
}

+ (void)showWithMessage:(NSString *)message inView:(UIView *)view
{
    [RSTToastView showWithMessage:message inView:view duration:0];
}

+ (void)showWithMessage:(NSString *)message inView:(UIView *)view duration:(NSTimeInterval)duration
{
    [RSTToastView rst_showWithMessage:message inView:view duration:duration showsActivityIndicator:NO];
}

+ (void)showWithActivityMessage:(NSString *)message
{
    [RSTToastView showWithActivityMessage:message duration:0];
}

+ (void)showWithActivityMessage:(NSString *)message duration:(NSTimeInterval)duration
{
    [RSTToastView showWithActivityMessage:message inView:[RSTToastView presentationWindow] duration:duration];
}

+ (void)showWithActivityMessage:(NSString *)message inView:(UIView *)view
{
    [RSTToastView showWithActivityMessage:message inView:view duration:0];
}

+ (void)showWithActivityMessage:(NSString *)message inView:(UIView *)view duration:(NSTimeInterval)duration
{
    [RSTToastView rst_showWithMessage:message inView:view duration:duration showsActivityIndicator:YES];
}

+ (void)rst_showWithMessage:(NSString *)message inView:(UIView *)view duration:(NSTimeInterval)duration showsActivityIndicator:(BOOL)showsActivityIndicator
{
    _globalToastView = ({
        RSTToastView *toastView = [RSTToastView toastViewWithMessage:message];
        toastView.showsActivityIndicator = showsActivityIndicator;
        
        if (duration > 0)
        {
            toastView.hidingTimer = [NSTimer scheduledTimerWithTimeInterval:duration target:toastView selector:@selector(hide) userInfo:nil repeats:NO];
        }
        
        toastView;
    });
    
    [_globalToastView showInView:view duration:duration];
}

- (void)show
{
    [self showForDuration:0];
}

- (void)showForDuration:(NSTimeInterval)duration
{
    [self showInView:[RSTToastView presentationWindow] duration:duration];
}

- (void)showInView:(UIView *)view
{
    [self showInView:view duration:0];
}

- (void)showInView:(UIView *)view duration:(NSTimeInterval)duration
{
    // Show Presentation Window if needed
    if (view == [RSTToastView presentationWindow] && [view isHidden])
    {
        [[RSTToastView presentationWindow] setHidden:NO];
        [[RSTToastView presentationWindow] setWindowLevel:UIWindowLevelNormal];
    }
    
    
    // Duration Timer
    [self.hidingTimer invalidate];
    
    if (duration > 0)
    {
        self.hidingTimer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hide) userInfo:nil repeats:NO];
    }
    else
    {
        self.hidingTimer = nil;
    }
    

    BOOL dismissBeforePresenting = ([self isVisible] && (self.currentPresentationEdge != self.presentationEdge || self.currentAlignmentEdge != self.alignmentEdge || self.presentationView != view));
    
    // If toast view should be shown in a new position, dismiss it first before presenting again
    if (dismissBeforePresenting)
    {
        self.presentAfterHiding = YES;
        [self hide];
    }
    
    // Must set these after (potentially) hiding toast view
    self.currentPresentationEdge = self.presentationEdge;
    self.currentAlignmentEdge = self.alignmentEdge;
    self.presentationView = view;
    
    if (dismissBeforePresenting)
    {
        return;
    }
    
    // If toast view is already visible and is not currently being hidden, no need to do anything else
    if ([self isVisible] && ![self isBeingHidden])
    {
        return;
    }
    
    
    // Applies UIAppearance after added to a view
    [view addSubview:self];
    
    [self rst_refreshLayout];
    
    
    if (![self isVisible])
    {
        self.frame = [RSTToastView rst_initialFrameForToastView:self];
        
        if ([self.delegate respondsToSelector:@selector(toastViewWillShow:)])
        {
            [self.delegate toastViewWillShow:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RSTToastViewWillShowNotification object:self];
    }
    
    if ([self isBeingHidden])
    {
        self.frame = [self.layer.presentationLayer frame];
        [self.layer removeAllAnimations];
    }
    
    
    self.visible = YES;
    
    
    [UIView animateWithDuration:.8 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
        self.frame = [RSTToastView rst_finalFrameForToastView:self];
    } completion:^(BOOL finished) {
        
        if ([self.delegate respondsToSelector:@selector(toastViewDidShow:)])
        {
            [self.delegate toastViewDidShow:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RSTToastViewDidShowNotification object:self];
    }];
}

#pragma mark - Updating

+ (void)updateWithMessage:(NSString *)message
{
    [_globalToastView setMessage:message];
    [_globalToastView setShowsActivityIndicator:NO];
}

+ (void)updateWithActivityMessage:(NSString *)message
{
    [_globalToastView setMessage:message];
    [_globalToastView setShowsActivityIndicator:YES];
}

- (void)rst_refreshLayout
{
    [self.messageLabel sizeToFit];
    
    CGFloat buffer = 10.0f;
    
    CGFloat width = 0;
    
    if (self.width == RSTToastViewMaximumWidth)
    {
        width = [RSTToastView rst_maximumWidthForToastView:self];
    }
    else if (self.width == RSTToastViewAutomaticWidth)
    {
        width = CGRectGetWidth(self.messageLabel.bounds) + buffer * 2.0f;
    }
    else
    {
        width = self.width;
    }
    
    CGFloat height = CGRectGetHeight(self.messageLabel.bounds) + buffer;
    
    CGFloat xOffset = buffer;
    
    if (![self.activityIndicatorView isHidden])
    {
        width += CGRectGetWidth(self.activityIndicatorView.bounds) + buffer * .75;
        height = CGRectGetHeight(self.activityIndicatorView.bounds) + buffer;
        
        xOffset = CGRectGetWidth(self.activityIndicatorView.bounds) + buffer * 1.75;
    }
    
    CGFloat maximumWidth = [RSTToastView rst_maximumWidthForToastView:self];
    width = fminf(maximumWidth, width);
    
    self.messageLabel.frame = ({
        CGRect frame = self.messageLabel.frame;
        frame.size.width = width - (xOffset + buffer);
        frame;
    });
    
    
    self.bounds = CGRectMake(0, 0, width, height);
    
    self.activityIndicatorView.center = CGPointMake(buffer + CGRectGetMidX(self.activityIndicatorView.bounds), CGRectGetMidY(self.bounds));
    
    self.messageLabel.frame = CGRectIntegral(CGRectMake(xOffset, (height - CGRectGetHeight(self.messageLabel.bounds))/2.0f, CGRectGetWidth(self.messageLabel.bounds), CGRectGetHeight(self.messageLabel.bounds)));
    
    CGFloat cornerRadius = self.cornerRadius;
        
    if (cornerRadius == RSTToastViewCornerRadiusAutomaticRoundedDimension)
    {
        cornerRadius = CGRectGetHeight(self.bounds) / 2.0;
    }
    
    self.layer.cornerRadius = cornerRadius;
    
    [self setNeedsDisplay];
    
    self.frame = [RSTToastView rst_finalFrameForToastView:self];
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
}

#pragma mark - Dismissal

+ (void)hide
{
    [_globalToastView hide];
}

- (void)hide
{
    if ([self isBeingHidden])
    {
        return;
    }
    
    if (![self isVisible])
    {
        return;
    }
    
    self.beingHidden = YES;
    
    if (!self.presentAfterHiding)
    {
        [self.hidingTimer invalidate];
    }
    
    
    CGRect initialFrame = [RSTToastView rst_initialFrameForToastView:self];
    
    if ([self.delegate respondsToSelector:@selector(toastViewWillHide:)])
    {
        [self.delegate toastViewWillHide:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RSTToastViewWillHideNotification object:self];
    
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.frame = initialFrame;
    } completion:^(BOOL finished) {
        
        self.beingHidden = NO;
        
        if (!finished)
        {
            // Cancelled, so still visible
            return;
        }
        
        [self removeFromSuperview];
        self.visible = NO;
        
        if ([self.delegate respondsToSelector:@selector(toastViewDidHide:)])
        {
            [self.delegate toastViewDidHide:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RSTToastViewDidHideNotification object:self];
    }];
}

#pragma mark - Interaction

- (void)rst_toastViewWasTapped:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if ([self.delegate respondsToSelector:@selector(toastViewWasTapped:)])
    {
        [self.delegate toastViewWasTapped:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RSTToastViewWasTappedNotification object:self];
}

#pragma mark - Helper Methods

+ (CGAffineTransform)rst_transformForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (interfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
            transform = CGAffineTransformIdentity;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270.0f));
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180.0f));
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90.0f));
            break;
    }
    
    return transform;
}

+ (CGRect)rst_initialFrameForToastView:(RSTToastView *)toastView
{
    CGFloat edgeBuffer = 40.0f; // Intentionally not self.edgeSpacing; this should be consistent. The offset the toast view is beyond the presentation view's bounds
    
    CGRect frame = [RSTToastView rst_finalFrameForToastView:toastView];
    CGRect bounds = toastView.bounds;
    
    switch (toastView.currentPresentationEdge)
    {
        case UIRectEdgeTop:
        {
            frame.origin.y = -(CGRectGetHeight(bounds) + edgeBuffer);
            break;
        }
            
        case UIRectEdgeLeft:
        {
            frame.origin.x = -(CGRectGetWidth(bounds) + edgeBuffer);
            break;
        }
            
        case UIRectEdgeRight:
        {
            frame.origin.x = CGRectGetWidth(toastView.presentationView.bounds) + edgeBuffer;
            break;
        }
            
        default: // Bottom or any other edge
        {
            frame.origin.y = CGRectGetHeight(toastView.presentationView.bounds) + edgeBuffer;
            break;
        }
    }
    
    return frame;
}

+ (CGRect)rst_finalFrameForToastView:(RSTToastView *)toastView
{
    UIView *view = toastView.presentationView;
    CGSize size = toastView.bounds.size;
    
    UIRectEdge presentationEdge = toastView.currentPresentationEdge; // Use current value in case it was changed, but hasn't yet been dismissed
    UIRectEdge alignmentEdge = toastView.currentAlignmentEdge; // Use current value in case it was changed, but hasn't yet been dismissed

    CGFloat originX = 0.0;
    CGFloat originY = 0.0;
    
    switch (alignmentEdge)
    {
        case UIRectEdgeTop:
            originY = toastView.edgeSpacing;
            break;
            
        case UIRectEdgeLeft:
            originX = toastView.edgeSpacing;
            break;
            
        case UIRectEdgeRight:
            originX = CGRectGetWidth(view.bounds) - size.width - toastView.edgeSpacing;
            break;
            
        default:
            originY = CGRectGetHeight(view.bounds) - size.height - toastView.edgeSpacing;
            break;
    }
    
    switch (presentationEdge)
    {
        case UIRectEdgeTop:
        {
            if (alignmentEdge == UIRectEdgeTop || alignmentEdge == UIRectEdgeBottom || alignmentEdge == UIRectEdgeNone)
            {
                originX = CGRectGetMidX(view.bounds) - (size.width / 2.0f);
            }
            
            originY = toastView.edgeSpacing;
            break;
        }
            
        case UIRectEdgeLeft:
        {
            if (alignmentEdge == UIRectEdgeLeft || alignmentEdge == UIRectEdgeRight || alignmentEdge == UIRectEdgeNone)
            {
                originY = CGRectGetMidY(view.bounds) - (size.height / 2.0f);
            }
            
            originX = toastView.edgeSpacing;
            break;
        }
            
        case UIRectEdgeRight:
        {
            if (alignmentEdge == UIRectEdgeLeft || alignmentEdge == UIRectEdgeRight || alignmentEdge == UIRectEdgeNone)
            {
                originY = CGRectGetMidY(view.bounds) - (size.height / 2.0f);
            }
            
            originX = CGRectGetWidth(view.bounds) - (size.width + toastView.edgeSpacing);
            break;
        }
            
        default: // Bottom or any other edge
        {
            if (alignmentEdge == UIRectEdgeTop || alignmentEdge == UIRectEdgeBottom || alignmentEdge == UIRectEdgeNone)
            {
                originX = CGRectGetMidX(view.bounds) - (size.width / 2.0f);
            }
            
            originY = CGRectGetHeight(view.bounds) - (size.height + toastView.edgeSpacing);
            break;
        }
    }
    
    return CGRectIntegral(CGRectMake(originX, originY, size.width, size.height));
}

+ (CGFloat)rst_maximumWidthForToastView:(RSTToastView *)toastView
{
    UIView *view = toastView.presentationView;
    CGFloat maximumWidth = CGRectGetWidth(view.bounds);
    
    maximumWidth -= toastView.edgeSpacing * 2.0f;
    
    return maximumWidth;
}

+ (UIViewAutoresizing)rst_autoresizingMaskForPresentationEdge:(UIRectEdge)presentationEdge alignmentEdge:(UIRectEdge)alignmentEdge
{
    UIViewAutoresizing autoresizingMask = UIViewAutoresizingNone;
    
    switch (presentationEdge)
    {
        case UIRectEdgeBottom:
            autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
            break;
            
        case UIRectEdgeTop:
            autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
            break;
            
        case UIRectEdgeLeft:
            autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
            break;
            
        case UIRectEdgeRight:
            autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            break;
            
        default:
            break;
    }
    
    if (alignmentEdge == UIRectEdgeNone)
    {
        alignmentEdge = presentationEdge;
    }
    
    switch (alignmentEdge)
    {
        case UIRectEdgeBottom:
            
            if (presentationEdge == UIRectEdgeLeft || presentationEdge == UIRectEdgeRight)
            {
                autoresizingMask |= UIViewAutoresizingFlexibleTopMargin;
            }
            else
            {
                autoresizingMask |= UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            }
            
            break;
            
        case UIRectEdgeTop:
            
            if (presentationEdge == UIRectEdgeLeft || presentationEdge == UIRectEdgeRight)
            {
                autoresizingMask |= UIViewAutoresizingFlexibleBottomMargin;
            }
            else
            {
                autoresizingMask |= UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            }
            
            break;
            
        case UIRectEdgeLeft:
            
            if (presentationEdge == UIRectEdgeTop || presentationEdge == UIRectEdgeBottom)
            {
                autoresizingMask |= UIViewAutoresizingFlexibleRightMargin;
            }
            else
            {
                autoresizingMask |= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            }
            
            break;
            
        case UIRectEdgeRight:
            
            if (presentationEdge == UIRectEdgeTop || presentationEdge == UIRectEdgeBottom)
            {
                autoresizingMask |= UIViewAutoresizingFlexibleLeftMargin;
            }
            else
            {
                autoresizingMask |= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            }
            
            break;
            
        default:
            break;
    }
    
    return autoresizingMask;
}

#pragma mark - Notifications

- (void)rst_willShowToastView:(NSNotification *)notification
{
    RSTToastView *toastView = [notification object];
    
    // If the new toast view is presenting from the same edge as the current toast view, hide the current one
    if (self.presentationEdge == toastView.presentationEdge && self.superview == toastView.superview && [self isVisible])
    {
        [self hide];
    }
}

- (void)rst_didHideToastView:(NSNotification *)notification
{
    RSTToastView *toastView = [notification object];
    
    if (self != toastView)
    {
        return;
    }
    
    if (self.presentAfterHiding)
    {
        [self showInView:self.presentationView];
        self.presentAfterHiding = NO;
    }
}

- (void)rst_willChangeStatusBarOrientation:(NSNotification *)notification
{
    if (![self isVisible] || self.superview != self.window)
    {
        return;
    }
    
    // If the timer is valid, it hasn't yet started to dismiss
    if (![self isBeingHidden])
    {
        self.presentAfterHiding = YES;
    }
    
    [self hide];
}


#pragma mark - Getters/Setters

- (void)setPresentationEdge:(UIRectEdge)presentationEdge
{
    UIRectEdge sanitizedPresentationEdge = UIRectEdgeBottom;
    
    if (presentationEdge & UIRectEdgeBottom)
    {
        sanitizedPresentationEdge = UIRectEdgeBottom;
    }
    else if (presentationEdge & UIRectEdgeTop)
    {
        sanitizedPresentationEdge = UIRectEdgeTop;
    }
    else if (presentationEdge & UIRectEdgeLeft)
    {
        sanitizedPresentationEdge = UIRectEdgeLeft;
    }
    else if (presentationEdge & UIRectEdgeRight)
    {
        sanitizedPresentationEdge = UIRectEdgeRight;
    }
    
    _presentationEdge = presentationEdge;
    
    self.autoresizingMask = [RSTToastView rst_autoresizingMaskForPresentationEdge:self.presentationEdge alignmentEdge:self.alignmentEdge];
}

- (void)setAlignmentEdge:(UIRectEdge)alignmentEdge
{
    UIRectEdge sanitizedAlignmentEdge = UIRectEdgeBottom;
    
    if (alignmentEdge & UIRectEdgeBottom)
    {
        sanitizedAlignmentEdge = UIRectEdgeBottom;
    }
    else if (alignmentEdge & UIRectEdgeTop)
    {
        sanitizedAlignmentEdge = UIRectEdgeTop;
    }
    else if (alignmentEdge & UIRectEdgeLeft)
    {
        sanitizedAlignmentEdge = UIRectEdgeLeft;
    }
    else if (alignmentEdge & UIRectEdgeRight)
    {
        sanitizedAlignmentEdge = UIRectEdgeRight;
    }
    
    _alignmentEdge = alignmentEdge;
    
    self.autoresizingMask = [RSTToastView rst_autoresizingMaskForPresentationEdge:self.presentationEdge alignmentEdge:self.alignmentEdge];
}

- (void)setMessage:(NSString *)message
{
    if ([self.messageLabel.text isEqualToString:message])
    {
        return;
    }
    
    self.messageLabel.text = message;
    
    [self rst_refreshLayout];
}

- (NSString *)message
{
    return self.messageLabel.text;
}

- (void)setFont:(UIFont *)font
{
    // Update any logic here in the initialization method too
    if ([self.messageLabel.font isEqual:font])
    {
        return;
    }
    
    self.messageLabel.font = font;
    
    [self rst_refreshLayout];
}

- (UIFont *)font
{
    return [self.messageLabel font];
}

- (void)setShowsActivityIndicator:(BOOL)showsActivityIndicator
{
    if ([self.activityIndicatorView isAnimating] == showsActivityIndicator)
    {
        return;
    }
    
    if (showsActivityIndicator)
    {
        [self.activityIndicatorView startAnimating];
    }
    else
    {
        [self.activityIndicatorView stopAnimating];
    }
    
    [self rst_refreshLayout];
}

- (BOOL)showsActivityIndicator
{
    return [self.activityIndicatorView isAnimating];
}

- (void)setAlpha:(CGFloat)alpha
{
    [super setAlpha:alpha];
}

- (CGFloat)alpha
{
    return [super alpha];
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
}

- (UIColor *)tintColor
{
    return [super tintColor];
}

- (void)tintColorDidChange
{
    self.backgroundColor = self.tintColor;
}

#ifndef RST_APP_EXTENSION

+ (RSTPresentationWindow *)presentationWindow
{
    static RSTPresentationWindow *_presentationWindow = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _presentationWindow = [RSTPresentationWindow new];
        _presentationWindow.windowLevel = -1;
    });
    
    return _presentationWindow;
}

#else

+ (UIWindow *)presentationWindow
{
    return [UIWindow new];
}

#endif

@end
