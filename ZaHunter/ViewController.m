//
//  ViewController.m
//  ZaHunter
//
//  Created by Chris Snyder on 8/7/14.
//  Copyright (c) 2014 Chris Snyder. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "PizzaLocationViewController.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *pizzaViewController;
@property CLLocationManager *myLocationManager;
@property CLLocation *currentLocation;
@property NSArray *pizzaStores;
@property (weak, nonatomic) IBOutlet UILabel *tableFooterView;
@property NSTimeInterval totalPizzaingTime;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.pizzaStores = [NSArray new];
    self.myLocationManager = [[CLLocationManager alloc]init];
    self.myLocationManager.delegate = self;
    [self.myLocationManager startUpdatingLocation];
}
-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footer = [[UIView alloc]initWithFrame:CGRectMake(0, 350, 220, 20)];
    footer.backgroundColor = [UIColor clearColor];

    self.tableFooterView.backgroundColor = [UIColor redColor];
    self.tableFooterView.text = [NSString stringWithFormat:@"Your total pizzaing time is: %i minutes",(int)self.totalPizzaingTime];
    self.tableFooterView.textAlignment = NSTextAlignmentCenter;
    [footer addSubview:self.tableFooterView];

     [footer addSubview:self.tableFooterView];

    return footer;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10.0;
}
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations)
    {
        if (location.verticalAccuracy > 1000 || location.horizontalAccuracy > 1000)
        {
            continue;
        }
        self.currentLocation = location;
        [self.myLocationManager stopUpdatingLocation];
        break;
    }
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizza";

    MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);
    CLLocationCoordinate2D coordinate = [self.currentLocation coordinate];
    request.region = MKCoordinateRegionMake(coordinate, span);

    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
     {
         self.pizzaStores = response.mapItems;
         self.pizzaStores = [self.pizzaStores sortedArrayUsingComparator:^NSComparisonResult(MKMapItem* obj1, MKMapItem* obj2)
                         {
                             return [self.currentLocation distanceFromLocation:obj1.placemark.location] - [self.currentLocation distanceFromLocation:obj2.placemark.location];
                         }];
         self.pizzaStores = [self.pizzaStores subarrayWithRange:NSMakeRange(0, 4)];

         [self.pizzaViewController reloadData];
     }];
}

-(void)getTotalEatingTime:(MKDirectionsTransportType)transportType
{
    MKMapItem *source = [MKMapItem mapItemForCurrentLocation];
    for (MKMapItem *result in self.pizzaStores) {
        MKDirectionsRequest *request = [MKDirectionsRequest new];
        request.transportType = transportType;
        request.source = source;
        request.destination = result;
        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error)
         {
             MKRoute *route = response.routes.firstObject;
             self.totalPizzaingTime += route.expectedTravelTime/60 + 50;
             self.tableFooterView.text = [NSString stringWithFormat:@"Your total pizzaing time is: %i minutes",(int)self.totalPizzaingTime];
         }];
        source = result;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    MKMapItem *pizzaResult = [self.pizzaStores objectAtIndex:indexPath.row];
    cell.textLabel.text = pizzaResult.name;

    return  cell;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  self.pizzaStores.count;
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

}
@end
