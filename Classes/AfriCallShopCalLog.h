//
//  AfriCallShopCalLog.h
//  linphone
//
//  Created by Abdel Karim on 17/11/13.
//
//

#import <Foundation/Foundation.h>

@interface AfriCallShopCalLog : NSObject
@property (nonatomic,retain) NSString *to;
@property (nonatomic,retain) NSString *rate;
@property (nonatomic,retain) NSString *calledCountry;
@property (nonatomic,retain) NSString *callDuration;
@property (nonatomic,retain) NSDate *callDate;
@property (nonatomic,retain) NSString *nom_contact;
@end
