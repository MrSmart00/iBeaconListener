//
//  BeaconListener.m
//  iBeaconExample
//
//  Created by 日野森寛也 on 8/4/14.
//  Copyright (c) 2014 Hiroya Hinomori. All rights reserved.
//  This software is released under the MIT License.
//  http://opensource.org/licenses/mit-license.php
//

#import "BeaconListener.h"

@interface BeaconListener () {
    CLLocationManager* locationManager;
    CLProximity prevProxi;
    ErrorRegion errorBlock;
    EnterRegion enterBlock;
    ExitRegion exitBlock;
    RangingRegion rangingBlock;
    NSMutableDictionary* regions;
}
@end


@implementation BeaconListener

static BeaconListener* _sharedInstance = nil;

# pragma static methods

+ (BeaconListener*)sharedInstance {
	@synchronized(self) {
		if (_sharedInstance == nil) {
			_sharedInstance = [[self alloc] init];
		}
        return _sharedInstance;
	}
    return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        prevProxi = CLProximityUnknown;
        regions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addUUID:(NSString*)uuidStr
     identifier:(NSString*)regionIdentifier
          enter:(EnterRegion)enter
           exit:(ExitRegion)exit
        ranging:(RangingRegion)ranging
        failure:(ErrorRegion)failure
{
    [self addUUID:uuidStr major:0 minor:0 identifier:regionIdentifier enter:enter exit:exit ranging:ranging failure:failure];
}

- (void)addUUID:(NSString*)uuidStr
          major:(int)major
     identifier:(NSString*)regionIdentifier
          enter:(EnterRegion)enter
           exit:(ExitRegion)exit
        ranging:(RangingRegion)ranging
        failure:(ErrorRegion)failure
{
    [self addUUID:uuidStr major:major minor:0 identifier:regionIdentifier enter:enter exit:exit ranging:ranging failure:failure];
}

- (void)addUUID:(NSString*)uuidStr
          major:(int)major
          minor:(int)minor
     identifier:(NSString*)regionIdentifier
          enter:(EnterRegion)enter
           exit:(ExitRegion)exit
        ranging:(RangingRegion)ranging
        failure:(ErrorRegion)failure
{
    NSUUID* uuid = [[NSUUID alloc] initWithUUIDString:uuidStr];
    CLBeaconRegion* region;
    if (major >= 0 && minor >= 0) {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:major minor:minor identifier:regionIdentifier];
    } else if (major >= 0) {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:major identifier:regionIdentifier];
    } else {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:regionIdentifier];
    }
    region.notifyEntryStateOnDisplay = YES;
    
    errorBlock = failure;
    enterBlock = enter;
    exitBlock = exit;
    rangingBlock = ranging;
    
    if (!region) {
        failure(locationManager, [NSError errorWithDomain:@"RegionErrorDomain" code:-1000 userInfo:@{@"reason": @"Couldn't create CLBeaconRegion."}]);
    } else {
        [regions setObject:region forKey:uuid.UUIDString];
        [self startScan:region];
    }
}

- (void)startScan:(CLBeaconRegion*)region
{
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"Couldn't turn on ranging: Ranging is not available.");
        return;
    }
    
    if (locationManager.rangedRegions.count > 0) {
        NSEnumerator* enumerator = locationManager.rangedRegions.objectEnumerator;
        for (CLBeaconRegion* r in enumerator) {
            if ([r.proximityUUID isEqual:region.proximityUUID]) {
                if (region.major && region.minor) {
                    if ([r.major isEqualToNumber:region.major] && [r.minor isEqualToNumber:region.minor]) {
                        NSLog(@"Didn't turn on ranging: Ranging already on.");
                        return;
                    }
                } else if (region.major) {
                    if ([r.major isEqualToNumber:region.major]) {
                        NSLog(@"Didn't turn on ranging: Ranging already on.");
                        return;
                    }
                } else {
                    NSLog(@"Didn't turn on ranging: Ranging already on.");
                    return;
                }
            }
        }
    }
    
    [locationManager startMonitoringForRegion:region];
    [locationManager startRangingBeaconsInRegion:region];
}

- (void)stopScan:(NSString*)targetUUID
{
    CLBeaconRegion* region = [regions objectForKey:targetUUID];
    if (region) {
        [locationManager stopMonitoringForRegion:region];
        [locationManager stopRangingBeaconsInRegion:region];
    }
}

@end

@implementation BeaconListener (LocationManagerDelegate)

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    
    switch (state) {
        case CLRegionStateInside:
            if([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]){
                if (enterBlock) {
                    enterBlock(locationManager, region);
                }
            }
            break;
            
        case CLRegionStateOutside: {
            if([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]){
                if (exitBlock) {
                    exitBlock(locationManager, region);
                }
            }
            break;
        }
        case CLRegionStateUnknown:
        default:
            break;
    }
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"Couldn't turn on ranging: Location services are not enabled.");
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        NSLog(@"Couldn't turn on monitoring: Location services not authorised.");
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if (enterBlock) {
        enterBlock(locationManager, region);
    }

    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if (exitBlock) {
        exitBlock(locationManager, region);
    }
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (rangingBlock) {
        rangingBlock(locationManager, region, beacons);
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (errorBlock) {
        errorBlock(locationManager, error);
    }
    NSLog(@"didFailWithError : %@", error.description);
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    if (errorBlock) {
        errorBlock(locationManager, error);
    }
    NSLog(@"rangingBeaconsDidFailForRegion : %@", error.description);
}

@end