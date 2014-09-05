//
//  BeaconListener.h
//  iBeaconExample
//
//  Created by 日野森寛也 on 8/4/14.
//  Copyright (c) 2014 Hiroya Hinomori. All rights reserved.
//
//  This software is released under the MIT License.
//  http://opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^ErrorRegion)(CLLocationManager* manager, NSError* error);    //!< iBeacon情報取得エラーブロック
typedef void (^EnterRegion)(CLLocationManager* manager, CLRegion* region);  //!< iBeaconエリア入場イベントブロック
typedef void (^ExitRegion)(CLLocationManager* manager, CLRegion* region);   //!< iBeaconエリア退場イベントブロック
typedef void (^RangingRegion)(CLLocationManager* manager, CLBeaconRegion* region, NSArray* beacons);    //!< iBeacon探索結果取得ブロック

@interface BeaconListener : NSObject
/**
 シングルトンインスタンスの取得
 @return BeaconListener
 */
+ (BeaconListener*)sharedInstance;
/**
 探索iBeaconUUID登録
 @param uuidStr 探索するiBeaconのUUID
 @param enter 対象のiBeaconが有効になるエリア入場時のイベントブロック
 @param exit 対象のiBeaconが有効になるエリア退場時のイベントブロック
 @param ranging 探索結果取得ブロック
 @param failure 探索失敗ブロック
 */
- (void)addUUID:(NSString*)uuidStr
     identifier:(NSString*)regionIdentifier
          enter:(EnterRegion)enter
           exit:(ExitRegion)exit
        ranging:(RangingRegion)ranging
        failure:(ErrorRegion)failure;
/**
 探索iBeaconUUID登録
 @param uuidStr 探索するiBeaconのUUID
 @param major 探索するiBeaconのmajor値
 @param enter 対象のiBeaconが有効になるエリア入場時のイベントブロック
 @param exit 対象のiBeaconが有効になるエリア退場時のイベントブロック
 @param ranging 探索結果取得ブロック
 @param failure 探索失敗ブロック
 */
- (void)addUUID:(NSString*)uuidStr
          major:(int)major
     identifier:(NSString*)regionIdentifier
          enter:(EnterRegion)enter
           exit:(ExitRegion)exit
        ranging:(RangingRegion)ranging
        failure:(ErrorRegion)failure;
/**
 探索iBeaconUUID登録
 @param uuidStr 探索するiBeaconのUUID
 @param major 探索するiBeaconのmajor値
 @param minor 探索するiBeaconのminor値
 @param enter 対象のiBeaconが有効になるエリア入場時のイベントブロック
 @param exit 対象のiBeaconが有効になるエリア退場時のイベントブロック
 @param ranging 探索結果取得ブロック
 @param failure 探索失敗ブロック
 */
- (void)addUUID:(NSString*)uuidStr
          major:(int)major
          minor:(int)minor
     identifier:(NSString*)regionIdentifier
          enter:(EnterRegion)enter
           exit:(ExitRegion)exit
        ranging:(RangingRegion)ranging
        failure:(ErrorRegion)failure;
/**
 対象UUIDのiBeacon探索を終了する
 @param targetUUID 終了するiBeaconのUUID
 */
- (void)stopScan:(NSString*)targetUUID;
@end

@interface BeaconListener (LocationManagerDelegate) <CLLocationManagerDelegate>

@end
