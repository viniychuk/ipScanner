//
//  AppDelegate.m
//  IpScanner
//
//  Created by Alexandr Viniychuk on 2/17/15.
//  Copyright (c) 2015 Alexandr Viniychuk. All rights reserved.
//

#import "AppDelegate.h"
#import <CFNetwork/CFNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "SimplePing.h"
#include <arpa/inet.h>
#include <netinet/in.h>

@interface AppDelegate () {
    BOOL _isStarted;
}
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_inputFrom setStringValue:@"10.0.1.1"];
    [_inputTo setStringValue:@"10.0.1.254"];
    _isStarted = NO;
}

- (void)startPing {
    NSRange maskStart = [[_inputFrom stringValue] rangeOfString:@"." options:NSBackwardsSearch];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"You've entered incorrect IP range"];
    [alert setInformativeText:@"Check the IP range, ip from and ip to should start with the same mask A.B.C.x"];

    if (maskStart.location != NSNotFound) {
        NSString *mask = [[_inputFrom stringValue] substringWithRange:NSMakeRange(0, maskStart.location)];
        if ([[_inputTo stringValue] rangeOfString:mask].location != 0) {
            [_startStopButton setState:NSOffState];
            [alert runModal];
            return;
        }
    } else {
        [_startStopButton setState:NSOffState];
        [alert runModal];
        return;
    }
    
    _pingers = [[NSMutableArray alloc] init];
    NSLog(@"Starting app...");
    NSString *host;
    for(int i=1; i < 255 ; i++) {
        host = [NSString stringWithFormat:@"10.0.1.%d", i];
        SimplePing *ping = [SimplePing simplePingWithHostName:host];
        ping.delegate = self;
        [ping start];
        [_pingers addObject:ping];
    }
    [_startStopButton setState:NSOffState];    
}

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    const struct sockaddr * addrPtr;
    addrPtr = (const struct sockaddr *) [address bytes];
    
//    const struct sockaddr_in *sockIn = (const struct sockaddr_in *) [address bytes];
    
//    NSLog(@"started with %s", inet_ntoa(sockIn->sin_addr));
    [pinger sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
    NSLog(@"didFail");
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet {
//    NSLog(@"send packet");
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error {
    NSLog(@"fail to send packet");
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet {
//    const struct sockaddr_in *sockIn = (const struct sockaddr_in *) [packet bytes];
    [[self availabeHosts] addObject:[pinger hostName]];
    NSLog(@"receieve %@", [pinger hostName]);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)startStopScan:(id)sender {
    if ([_startStopButton state] == NSOnState) {
        NSRange range = NSMakeRange(0, [[self.availabeHosts arrangedObjects] count]);
        [self.availabeHosts removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
        [self startPing];
    }
}
@end
