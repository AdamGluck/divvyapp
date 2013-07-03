//
//  ViewController.m
//  DivvyApp
//
//  Created by Adam Gluck on 7/2/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import "ViewController.h"
#import "BGLDivvyDataAccess.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <BGLDivvyDataAccessDelegate>{
    int count;
}

@property (strong, nonatomic) BGLDivvyDataAccess * dataAccess;
@property (strong, nonatomic) IBOutlet UITextField *nearestLocationText;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.dataAccess = [[BGLDivvyDataAccess alloc] init];
    
    self.dataAccess.delegate = self;
    [self.dataAccess fillStationDataASynchronously];
    
    // "latitude":41.8739580629,"longitude":-87.6277394859 should be the station on State St & Harrison St
    // for testing
    
}

-(void) asynchronousFillRequestComplete: (NSArray *) data{
    NSLog(@"this means that your fill request is complete");
}

-(void) requestFailedWithError:(NSError *)error{
    NSLog(@"ERROR!!!");
}

-(void) nearestStationToDeviceFoundWithStation:(NSDictionary *)station{
    NSLog(@"station nearest to device %@ and name = %@", station, station[@"stationName"]);
    self.nearestLocationText.text = station[@"stationName"];
}

-(void) deviceLocationFoundAtLocation: (CLLocation *) location{
    //NSLog(@"device location %@", location);
}

- (IBAction)nearestLocationButtonPressed:(id)sender {
    [self.dataAccess grabNearestStationToDevice];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
