//
//  AppDelegate.h
//  IpScanner
//
//  Created by Alexandr Viniychuk on 2/17/15.
//  Copyright (c) 2015 Alexandr Viniychuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SimplePing.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, SimplePingDelegate>
@property (weak) IBOutlet NSTextField *inputFrom;
@property (weak) IBOutlet NSTextField *inputTo;
@property (weak) IBOutlet NSScrollView *tableAvailable;
@property (weak) IBOutlet NSArrayController *availabeHosts;
- (IBAction)startStopScan:(id)sender;
@property (weak) IBOutlet NSButton *startStopButton;
@property (weak) IBOutlet NSTextField *ipAddressLabel;

@property NSMutableArray *pingers;

@end