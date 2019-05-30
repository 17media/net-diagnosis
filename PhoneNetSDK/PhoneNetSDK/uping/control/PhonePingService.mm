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
    if (self.uIsPing) {
        return;
    }
    
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

#pragma mark-UCPingDelegate
- (void)pingResultWithUCPing:(PhonePing *)ucPing pingResult:(PPingResModel *)pingRes pingStatus:(PhoneNetPingStatus)status {
    if (self.pingResultHandler) {
        if (status == PhoneNetPingStatusFinished && self.pings.count > 0) {
            CGFloat time = 0.0f;
            NSInteger ttl = 0;
            NSMutableArray<NSString *> *allStatus = [[NSMutableArray alloc] init];
            
            for (PPingResModel *p in self.pings) {
                time += p.timeMilliseconds;
                ttl += p.timeToLive;
                NSString *pingStatus = [self statusString:p.status];
                [allStatus addObject:pingStatus];
            }
            
            time = time/(CGFloat)self.pings.count;
            ttl = ttl/self.pings.count;
            
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
}


@end
