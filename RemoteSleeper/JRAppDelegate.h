//
//  JRAppDelegate.h
//  RemoteSleeper
//
//  Created by James Reuss on 23/12/2012.
//  Copyright (c) 2012 James Reuss. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HostInfo.h"
#import "DFSSHConnectionType.h"
#import "DFSSHConnector.h"
#import "DFSSHOperator.h"
#import "DFSSHServer.h"

@interface JRAppDelegate : NSObject <NSApplicationDelegate> {
	BOOL isSleepEnabled;
}

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (assign) IBOutlet NSTextField *hostIP;
@property (assign) IBOutlet NSTextField *hostUser;
@property (assign) IBOutlet NSSecureTextField *hostPassword;
@property (assign) IBOutlet NSButton *sleepEnabled;
@property (assign) IBOutlet NSTextField *sshLog;

- (IBAction)saveAction:(id)sender;
- (IBAction)enableRemoteSleep:(id)sender;

@end
