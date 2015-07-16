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
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>

@interface AppDelegate () {
    BOOL _isStarted;
}
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"%@", [[[NSHost currentHost] addresses] objectAtIndex:0]);
    NSString *internalIp = [self getInternalIP];
    NSString *mask = [internalIp substringWithRange:NSMakeRange(0, [internalIp rangeOfString:@"." options:NSBackwardsSearch].location)];
    [_ipAddressLabel setStringValue:[NSString stringWithFormat:@"You IP: %@ / detecting external IP...", internalIp]];
    [_inputFrom setStringValue:[NSString stringWithFormat:@"%@.1", mask]];
    [_inputTo setStringValue:[NSString stringWithFormat:@"%@.254", mask]];
    _isStarted = NO;
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateExternalIp) userInfo:nil repeats:NO];
}

- (void)updateExternalIp {
    [_ipAddressLabel setStringValue:[NSString stringWithFormat:@"You IP: %@ / %@", [self getInternalIP], [self getExternalIP]]];
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
    NSString *mask = [[_inputFrom stringValue] substringToIndex:maskStart.location];
    for(int i=1; i < 255 ; i++) {
        host = [mask stringByAppendingFormat:@".%d", i];
        SimplePing *ping = [SimplePing simplePingWithHostName:host];
        ping.delegate = self;
        [ping start];
        [_pingers addObject:ping];
    }
    [_startStopButton setState:NSOffState];    
}

-(NSString *)getInternalIP
{
    NSString *address = @"not detected";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Get NSString from C String
                address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

-(NSString*)getExternalIP
{
    NSUInteger  an_Integer;
    NSArray * ipItemsArray;
    NSString *externalIP;
    
    NSURL *iPURL = [NSURL URLWithString:@"http://www.dyndns.org/cgi-bin/check_ip.cgi"];
    
    if (iPURL) {
        NSError *error = nil;
        NSString *theIpHtml = [NSString stringWithContentsOfURL:iPURL encoding:NSUTF8StringEncoding error:&error];
        if (!error) {
            NSScanner *theScanner;
            NSString *text = nil;
            
            theScanner = [NSScanner scannerWithString:theIpHtml];
            
            while ([theScanner isAtEnd] == NO) {
                
                // find start of tag
                [theScanner scanUpToString:@"<" intoString:NULL] ;
                
                // find end of tag
                [theScanner scanUpToString:@">" intoString:&text] ;
                
                // replace the found tag with a space
                //(you can filter multi-spaces out later if you wish)
                theIpHtml = [theIpHtml stringByReplacingOccurrencesOfString:
                             [ NSString stringWithFormat:@"%@>", text]
                                                                 withString:@" "] ;
                ipItemsArray =[theIpHtml  componentsSeparatedByString:@" "];
                an_Integer=[ipItemsArray indexOfObject:@"Address:"];
                externalIP =[ipItemsArray objectAtIndex:  ++an_Integer];
            }
        } else {
            return @"not detected";
//            NSLog(@"Oops... g %d, %@", [error code], [error localizedDescription]);
        }
    }
    return externalIP;
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
//    NSHost *host = [NSHost hostWithAddress:[pinger hostName]];
    
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
