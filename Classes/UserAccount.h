//
//  UserAccount.h
//  linphone
//
//  Created by Abdel Karim on 17/11/13.
//
//

#import <Foundation/Foundation.h>

@interface UserAccount : NSObject
@property (nonatomic,retain) NSString *email;
@property (nonatomic,retain) NSString *firsPasswd;
@property (nonatomic,retain) NSString *username;
@property (nonatomic,retain) NSString *password;
@property (nonatomic,retain) NSString *balance;
@property (nonatomic,retain) NSString *dislayName;
@property (nonatomic,retain) NSString *server;
@property (nonatomic,retain) NSString *domain;
@property (nonatomic,retain) NSString *callerId;
@end
