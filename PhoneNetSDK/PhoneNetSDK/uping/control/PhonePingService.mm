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
        CGFloat maximumTime = 0.0f;
        CGFloat minimumTime = CGFLOAT_MAX;
        CGFloat averageTime = 0.0f;
        
        NSMutableArray<NSString *> *details = [[NSMutableArray alloc] init];
        NSInteger validCount = 0; // timeout, error 狀態時不列入最後的平均計算
        
        for (PPingResModel *p in self.pings) {
            NSString *pingStatus = [self statusString:p.status];
            /* 這邊有個奇怪的現象, timeMilliseconds有可能是0.4左右, 但是卻是正常的status,
               所以需要把這種奇怪情況不列入不計算 */
            if ([self isNormalStatus:p.status] && p.timeMilliseconds > 1.0f) {
                validCount += 1;
                averageTime += p.timeMilliseconds;
                
                if (p.timeMilliseconds > maximumTime) {
                    maximumTime = p.timeMilliseconds;
                }
                
                if (p.timeMilliseconds < minimumTime) {
                    minimumTime = p.timeMilliseconds;
                }
                
                NSString *pingDetail = [NSString stringWithFormat:@"%d bytes form %@: icmp_seq=%d ttl=%d time=%.3fms (%@)",(int)p.dateBytesLength,p.IPAddress,(int)p.ICMPSequence,(int)p.timeToLive,p.timeMilliseconds, pingStatus];
                
                [details addObject:pingDetail];
            }
        }
        NSString *result = [NSString stringWithFormat:@"round-trip min/avg/max = %.3f/%.3f/%.3f", minimumTime, averageTime, maximumTime];
        [details addObject:result];
    
        if (validCount > 0) {
            averageTime = averageTime/(CGFloat)validCount;
        }
        
        [self.pings removeAllObjects];
        
        self.pingResultHandler(minimumTime, averageTime, maximumTime, [details copy]);
        
    } else {
        if (pingRes) {
            [self.pings addObject:pingRes];
        }
    }
}


@end
