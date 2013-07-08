//
//  DivvyMapViewController.m
//  DivvyApp
//
//  Created by Andrew Beinstein on 7/7/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import "DivvyMapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>

@interface DivvyMapViewController ()
@property (weak, nonatomic) IBOutlet UIView *mapViewContainer;

@end

@implementation DivvyMapViewController {
    GMSMapView *mapView_;
}


- (void)loadMap
{
    NSLog(@"Loading map view");
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:41.8739580629 longitude:-87.6277394859 zoom:10]; // Chicago (zoomed out)
    mapView_ = [GMSMapView mapWithFrame:CGRectMake(0, 0, 200, 200) camera:camera];
    mapView_.myLocationEnabled = YES;
    [self.mapViewContainer addSubview:mapView_];
}

- (void)addMarkerForStation:(NSDictionary *)station
{
    GMSMarker *marker = [[GMSMarker alloc] init];
    CLLocationDegrees latitude = (CLLocationDegrees)[station[@"latitude"] floatValue];
    CLLocationDegrees longitude = (CLLocationDegrees)[station[@"longitude"] floatValue];
    marker.position = CLLocationCoordinate2DMake(latitude, longitude);
    marker.title = station[@"stationName"];
    marker.map = mapView_;
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
