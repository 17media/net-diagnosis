//
//  UCPingService.m
//  PingDemo
//
//  Created by ethan on 06/08/2018.
//  Copyright © 2018 mediaios. All rights reserved.
//

#import "PhonePingService.h"
#import "PhoneNetSDKConst.h"
#include "log4cplus_pn.h"


@interface PhonePingService()<PhonePingDelegate>

@property (copy, nonatomic, readonly) NetPingResultHandler pingResultHandler;
@property (strong, nonatomic) PhonePing *uPing;
@property (strong, nonatomic) NSMutableArray<PPingResModel *> *pings;

@end

@implementation PhonePingService

static PhonePingService *ucPingservice_instance = NULL;

- (instancetype)init {
    self = [super init];
    if (self) {
        _pings = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (instancetype)shareInstance {
    if (ucPingservice_instance == NULL) {
        ucPingservice_instance = [[PhonePingService alloc] init];
    }
    return ucPingservice_instance;
}

- (void)uStopPing {
    [self.uPing stopPing];
}

- (BOOL)uIsPing {
    return [self.uPing isPing];
}


- (void)startPingHost:(NSString *)host packetCount:(int)count resultHandler:(NetPingResultHandler)handler {
    if (_uPing) {
        _uPing = nil;
        _uPing = [[PhonePing alloc] init];

    }else{
        _uPing = [[PhonePing alloc] init];
    }
    
    _pingResultHandler = handler;
    _uPing.delegate = self;
    
    [_uPing startPingHosts:host packetCount:count];
}

- (NSString *)statusString:(PhoneNetPingStatus)status {
    switch (status) {
        case PhoneNetPingStatusError: return @"Error";
        case PhoneNetPingStatusDidTimeout: return @"Timeout";
        case PhoneNetPingStatusDidFailToSendPacket: return @"DidFailToSendPacket";
        case PhoneNetPingStatusDidReceiveUnexpectedPacket: return @"ReceiveUnexpectedPacket";
        default: return @"Normal";
    }
}

- (BOOL)isNormalStatus:(PhoneNetPingStatus)status {
    switch (status) {
        case PhoneNetPingStatusError:
        case PhoneNetPingStatusDidTimeout:
        case PhoneNetPingStatusDidFailToSendPacket:
        case PhoneNetPingStatusDidReceiveUnexpectedPacket:
            return NO;
        default:
            return YES;
    }
}

#pragma mark-UCPingDelegate
- (void)pingResultWithUCPing:(PhonePing *)ucPing pingResult:(PPingResModel *)pingRes pingStatus:(PhoneNetPingStatus)status {
    if (!self.pingResultHandler) {
        return;
    }
    
    if (status == PhoneNetPingStatusFinished && self.pings.count > 0) {
        CGFloat time = 0.0f;
        NSInteger ttl = 0;
        NSMutableArray<NSString *> *allStatus = [[NSMutableArray alloc] init];
        NSInteger validCount = 0; // timeout, error 狀態時不列入最後的平均計算
        
        for (PPingResModel *p in self.pings) {
            NSString *pingStatus = [self statusString:p.status];
            [allStatus addObject:pingStatus];
            
            /* 這邊有個奇怪的現象, timeMilliseconds有可能是0.4左右, 但是卻是正常的status,
               所以需要把這種奇怪情況不列入不計算 */
            if ([self isNormalStatus:p.status] && p.timeMilliseconds > 1.0f) {
                validCount += 1;
                time += p.timeMilliseconds;
                ttl += p.timeToLive;
            }
        }
        
        if (validCount > 0) {
            time = time/(CGFloat)validCount;
            ttl = ttl/validCount;
        }
        
        [self.pings removeAllObjects];
        
        NSString *statusResult = [allStatus componentsJoinedByString:@"/"];
        self.pingResultHandler(time, ttl, statusResult, YES);
        
    } else {
        if (pingRes) {
            [self.pings addObject:pingRes];
            self.pingResultHandler(pingRes.timeMilliseconds, pingRes.timeToLive, [self statusString:pingRes.status], NO);
        }
    }
}


@end
