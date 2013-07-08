//
//  DivvyHomeViewController.m
//  DivvyApp
//
//  Created by Andrew Beinstein on 7/7/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import "DivvyHomeViewController.h"
#import "DivvyMapViewController.h"

@interface DivvyHomeViewController ()
@property (weak, nonatomic) IBOutlet UITextField *startLocationInput;
@property (weak, nonatomic) IBOutlet UITextField *endLocationInput;
@property (strong, nonatomic) UITextField *activeField;

@end

@implementation DivvyHomeViewController

#define kOFFSET_FOR_KEYBOARD 80.0

- (IBAction)getDirections:(id)sender {
    // Possibly delete this method
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"moveToMap"]){
        ((DivvyMapViewController *) segue.destinationViewController).startLocation = self.startLocationInput.text;
        ((DivvyMapViewController *) segue.destinationViewController).endLocation = self.endLocationInput.text;
    }
}


- (void)keyboardWillShow
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    //Assign new frame to your view
    [self.view setFrame:CGRectMake(0,-200,320,460)]; //here taken -20 for example i.e. your view will be scrolled to -20. change its value according to your requirement.
    [UIView commitAnimations];
    
}

-(void)keyboardWillHide
{

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    [self.view setFrame:CGRectMake(0,0,320,460)];
    [UIView commitAnimations];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;

}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ([textField isEqual:self.startLocationInput]) {
        [self.endLocationInput becomeFirstResponder];
        return NO;
    } else if ([textField isEqual:self.endLocationInput]) {
        [textField resignFirstResponder];
        return YES;
    }
    
	return YES;
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //[self registerForKeyboardNotifications];
    self.startLocationInput.delegate = self;
    self.endLocationInput.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
}

/* Lazy Instantiation */
- (UITextField *)activeField
{
    if (!_activeField) _activeField = [[UITextField alloc] init];
    return _activeField;
}

@end
