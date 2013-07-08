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
#import "BGLDivvyDataAccess.h"
#import "GoogleBikeRoute.h"

@interface DivvyMapViewController () <BGLDivvyDataAccessDelegate, GoogleBikeRouteDelegate>
@property (weak, nonatomic) IBOutlet UIView *mapViewContainer;
@property (strong, nonatomic) BGLDivvyDataAccess * dataAccess;
@property (strong, nonatomic) CLLocation * currentLocation;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLRegion *chicagoRegion;

@property (strong, nonatomic) CLLocation *startLocation;
@property (strong, nonatomic) CLLocation *endLocation;
@end

@implementation DivvyMapViewController {
    GMSMapView *mapView_;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.dataAccess = [[BGLDivvyDataAccess alloc] init];
    
    self.dataAccess.delegate = self;
    // for testing
    // "latitude":41.8739580629,"longitude":-87.6277394859 should be the station on State St & Harrison St
    
    [self loadMap];
    
    [self.dataAccess fillStationDataSynchronously];
    [self.dataAccess grabNearestStationToDeviceWithOption:kNearestStationAny];
    
    [self geocodeStartAddress];
}

- (void)geocodeStartAddress
{
    [self.geocoder geocodeAddressString:self.startAddress
                               inRegion:self.chicagoRegion
                      completionHandler:^(NSArray *placemarks, NSError *error) {
                          NSLog(@"Start geocode completed");
                          self.startLocation = ((CLPlacemark *)placemarks[0]).location;
                          [self addMarkerAtLocation:self.startLocation withTitle:@"Start"];
                          [self geocodeEndAddress];
                          if (error) {
                              NSLog(@"Error in geocoder: %@", error);
                          }
                      }];
    

}

- (void)geocodeEndAddress
{
    [self.geocoder geocodeAddressString:self.endAddress
                               inRegion:self.chicagoRegion
                      completionHandler:^(NSArray *placemarks, NSError *error) {
                          NSLog(@"End geocode completed");
                          self.endLocation = ((CLPlacemark *)placemarks[0]).location;
                          [self addMarkerAtLocation:self.endLocation withTitle:@"End"];
                          [self findStations];
                          if (error) {
                              NSLog(@"Error in geocoder: %@", error);
                          }
                      }];
}

- (void)findStations
{
    BGLStationObject *pickupBikeStation = [self.dataAccess grabNearestStationTo:self.startLocation withOption:kNearestStationWithBike];
    
    BGLStationObject *dropoffBikeStation = [self.dataAccess grabNearestStationTo:self.endLocation withOption:kNearestStationOpen];
    
    [self addMarkerForStation:pickupBikeStation];
    [self addMarkerForStation:dropoffBikeStation];
    
}

- (void)loadMap
{
    NSLog(@"Loading map view");
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:41.8739580629 longitude:-87.6277394859 zoom:10]; // Chicago (zoomed out)
    mapView_ = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
    mapView_.myLocationEnabled = YES;
    self.view = mapView_;
}

// Adds a Google Maps marker at a station
- (void)addMarkerForStation:(BGLStationObject *)station
{
    GMSMarker *marker = [[GMSMarker alloc] init];
    CLLocationDegrees latitude = station.latitude; 
    CLLocationDegrees longitude = station.longitude; 
    marker.position = CLLocationCoordinate2DMake(latitude, longitude);
    marker.title = station.stationName; 
    marker.map = mapView_;
}

- (void)addMarkerAtLocation:(CLLocation *)location withTitle:(NSString *)title
{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = location.coordinate;
    marker.title = title;
    marker.map = mapView_;
}



-(void) deviceLocationFoundAtLocation:(CLLocation *)deviceLocation{
    self.currentLocation = deviceLocation;
}

-(void) nearestStationToDeviceFoundWithStation: (BGLStationObject *) station{
        
    NSString *positionString1 = [[NSString alloc] initWithFormat:@"%f,%f", self.currentLocation.coordinate.latitude,self.currentLocation.coordinate.longitude];
    
    NSString *positionString2 = [[NSString alloc] initWithFormat:@"%f,%f", station.latitude,station.longitude];
    

    NSArray * waypoints = @[positionString1, positionString2];
    GoogleBikeRoute * route = [[GoogleBikeRoute alloc] init];
    
    route.waypoints = [waypoints copy];
    route.appDoesUseGPS = YES;
    route.delegate = self;
    [route goWithTransportationType:kTransportationTypeBiking];
     

}

-(void) routeWithPolyline: (GMSPolyline *) polyline{
    polyline.map = mapView_;
}


-(void) directionsFromServer: (NSDictionary *) directionsDictionary{
   // NSLog(@"directions = %@", directionsDictionary);
}



/* Lazy Instantiation */
- (NSString *)startAddress
{
    if (!_startAddress) _startAddress = [[NSString alloc] init];
    return _startAddress;
}

- (NSString *)endAddress
{
    if (!_endAddress) _endAddress = [[NSString alloc] init];
    return _endAddress;
}

- (CLLocation *)startLocation
{
    if (!_startLocation) _startLocation = [[CLLocation alloc] init];
    return _startLocation;
}

- (CLLocation *)endLocation
{
    if (!_endLocation) _endLocation = [[CLLocation alloc] init];
    return _endLocation;
}

- (CLGeocoder *)geocoder
{
    if (!_geocoder) _geocoder = [[CLGeocoder alloc] init];
    return _geocoder;
}

- (CLRegion *)chicagoRegion
{
    if (!_chicagoRegion) {
        NSLog(@"Constructing chicago region");
        CLLocationCoordinate2D chicago = CLLocationCoordinate2DMake(41.8500, 87.6500);
        _chicagoRegion = [[CLRegion alloc] initCircularRegionWithCenter:chicago radius:100 identifier:@"Chicago"];
    }
    return _chicagoRegion;
}



@end
