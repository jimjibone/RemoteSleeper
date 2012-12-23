//
//  JRAppDelegate.m
//  RemoteSleeper
//
//  Created by James Reuss on 23/12/2012.
//  Copyright (c) 2012 James Reuss. All rights reserved.
//

#import "JRAppDelegate.h"

@interface JRAppDelegate ()
- (void)fileNotifications;
- (void)receiveSleepNote:(NSNotification*)note;
- (void)receiveWakeNote:(NSNotification*)note;
- (void)loadPreferences;
- (void)savePreferences;
@end

@implementation JRAppDelegate

- (void)dealloc
{
	[_persistentStoreCoordinator release];
	[_managedObjectModel release];
	[_managedObjectContext release];
    [super dealloc];
}

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	isSleepEnabled = [self.sleepEnabled state];
	[self loadPreferences];
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.jamesreuss.RemoteSleeper" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.jamesreuss.RemoteSleeper"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"RemoteSleeper" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"RemoteSleeper.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom] autorelease];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = [coordinator retain];
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)enableRemoteSleep:(id)sender {
	isSleepEnabled = [self.sleepEnabled state];
}

- (void)fileNotifications {
    //These notifications are filed on NSWorkspace's notification center, not the default
    // notification center. You will not receive sleep/wake notifications if you file
    //with the default notification center.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
														   selector: @selector(receiveSleepNote:)
															   name: NSWorkspaceWillSleepNotification object: NULL];
	
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
														   selector: @selector(receiveWakeNote:)
															   name: NSWorkspaceDidWakeNotification object: NULL];
}

// See https://developer.apple.com/library/mac/#qa/qa1340/_index.html#//apple_ref/doc/uid/DTS10003321
- (void)receiveSleepNote:(NSNotification*)note {
	[self.sshLog insertText:[NSString stringWithFormat:@"receiveSleepNote START: %@\n", [note name]]];
	
	if (isSleepEnabled) {
		/////////////
		// http://thebsdbox.co.uk
		/////////////
		// Create server instance (this can be passed around as it contains the socket info etc..)
		DFSSHServer *server = [[DFSSHServer alloc] init];
		[server setSSHHost:[self.hostIP stringValue]
					  port:22
					  user:[self.hostUser stringValue]
					   key:@""
					keypub:@""
				  password:[self.hostPassword stringValue]];
		
		// Create connection instance, this will be changed at a later date to use class methods so wont
		// need instantiating
		DFSSHConnector *connection = [[DFSSHConnector alloc] init];
		
		
		// Set connection status to Auto Detect (will check for keyboard/password/key)
		// and connect
		[connection connect:server connectionType:[DFSSHConnectionType auto]];
		
		// if connected try the following commands
		if ([server connectionStatus]) {
			[self.sshLog insertText:@"Server 1 connected"];
			
			//NSString *returnState = [DFSSHOperator execCommand:@"osascript -e 'tell application \"System Events\" to sleep'" server:server];
			NSString *returnState = [DFSSHOperator execCommand:@"open ~/Desktop" server:server];
			if (returnState) [self.sshLog insertText:returnState];
		}
		
		// Close connection
		[connection closeSSH:server];
		
		//release
		[connection release];
		[server release];
	}
	
	[self.sshLog insertText:[NSString stringWithFormat:@"receiveSleepNote END: %@\n", [note name]]];
}

- (void)receiveWakeNote:(NSNotification*)note {
	[self.sshLog insertText:[NSString stringWithFormat:@"receiveWakeNote: %@\n", [note name]]];
}

- (void)loadPreferences {
	NSManagedObjectContext *context = [self managedObjectContext];
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"HostInfo" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	
	NSError *error;
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
	if ([fetchedObjects count] == 0) {
		NSLog(@"There is no preference history.");
	} else if ([fetchedObjects count] == 1) {
		HostInfo *preference = [fetchedObjects objectAtIndex:0];
		[self.hostIP setStringValue:[preference ip]];
		[self.hostUser setStringValue:[preference user]];
	} else {
		NSLog(@"There are %lu objects. Stopping.", [fetchedObjects count]);
	}
}
- (void)savePreferences {
	NSManagedObjectContext *context = [self managedObjectContext];
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"HostInfo" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	
	NSError *error;
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
	if ([fetchedObjects count] == 0) {
		HostInfo *newPref = [NSEntityDescription insertNewObjectForEntityForName:@"HostInfo" inManagedObjectContext:context];
		[newPref setIp:[self.hostIP stringValue]];
		[newPref setUser:[self.hostUser stringValue]];
	} else if ([fetchedObjects count] == 1) {
		HostInfo *currentPref = [fetchedObjects objectAtIndex:0];
		[currentPref setIp:[self.hostIP stringValue]];
		[currentPref setUser:[self.hostUser stringValue]];
	} else {
		NSLog(@"There are %lu objects. Stopping.", [fetchedObjects count]);
	}
	
	if (![context save:&error]) {
		NSLog(@"Whoops! There was an error while saving: %@", [error localizedDescription]);
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	// Add the current settings to the managedObjectContext.
	if ([[self.hostIP stringValue] isNotEqualTo:@""]) {
		[self savePreferences];
	}
	
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
