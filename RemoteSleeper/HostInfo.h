//
//  HostInfo.h
//  RemoteSleeper
//
//  Created by James Reuss on 23/12/2012.
//  Copyright (c) 2012 James Reuss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HostInfo : NSManagedObject

@property (nonatomic, retain) NSString * ip;
@property (nonatomic, retain) NSString * user;

@end
