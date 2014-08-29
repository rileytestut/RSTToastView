//
//  ViewController.m
//  RSTToastView
//
//  Created by Riley Testut on 8/29/14.
//  Copyright (c) 2014 Riley Testut. All rights reserved.
//

#import "ViewController.h"
#import "RSTToastView.h"

@interface ViewController ()

@property (strong, nonatomic) RSTToastView *toastView;

@end

@implementation ViewController
            
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.toastView = [RSTToastView toastViewWithMessage:@"Testing RSTToastView!"];
    self.toastView.showsActivityIndicator = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changePresentationEdge:(UISegmentedControl *)sender
{
    UIRectEdge presentationEdge = UIRectEdgeNone;
    
    switch (sender.selectedSegmentIndex)
    {
        case 0:
            presentationEdge = UIRectEdgeTop;
            break;
            
        case 1:
            presentationEdge = UIRectEdgeBottom;
            break;
            
        case 2:
            presentationEdge = UIRectEdgeLeft;
            break;
            
        case 3:
            presentationEdge = UIRectEdgeRight;
            break;
            
        default:
            break;
    }
    
    self.toastView.presentationEdge = presentationEdge;
}

- (IBAction)changeAlignmentEdge:(UISegmentedControl *)sender
{
    UIRectEdge alignmentEdge = UIRectEdgeNone;
    
    switch (sender.selectedSegmentIndex)
    {
        case 0:
            alignmentEdge = UIRectEdgeNone;
            break;
            
        case 1:
            alignmentEdge = UIRectEdgeTop;
            break;
            
        case 2:
            alignmentEdge = UIRectEdgeBottom;
            break;
            
        case 3:
            alignmentEdge = UIRectEdgeLeft;
            break;
            
        case 4:
            alignmentEdge = UIRectEdgeRight;
            break;
            
        default:
            break;
    }
    
    self.toastView.alignmentEdge = alignmentEdge;
}

- (IBAction)presentToastView:(UIButton *)sender
{
    if ([self.toastView isVisible])
    {
        [self.toastView hide];
        [sender setTitle:@"Present RSTToastView" forState:UIControlStateNormal];
    }
    else
    {
        [self.toastView show];
        [sender setTitle:@"Dismiss RSTToastView" forState:UIControlStateNormal];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
     return UIInterfaceOrientationMaskAll;
}

@end
