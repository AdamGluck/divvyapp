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

@end

@implementation DivvyHomeViewController

- (IBAction)getDirections:(id)sender {
    // Possibly delete this method
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"moveToMap"]){
        ((DivvyMapViewController *) segue.destinationViewController).startLocation = self.startLocationInput.text;
        ((DivvyMapViewController *) segue.destinationViewController).endLocation = self.endLocationInput.text;
    }
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
