/* UIStateBar.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU Library General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */     

#import "UIStateBar.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UILinphone.h"
@implementation UIStateBar

@synthesize registrationStateImage;
@synthesize registrationStateLabel;
@synthesize callQualityImage;
@synthesize callSecurityImage;
@synthesize callSecurityButton;
@synthesize balance;

NSTimer *callQualityTimer;
NSTimer *callSecurityTimer;


#pragma mark - Lifecycle Functions

- (id)init {
    self = [super initWithNibName:@"UIStateBar" bundle:[NSBundle mainBundle]];
    if(self != nil) {
        self->callSecurityImage = nil;
        self->callQualityImage = nil;
        self->securitySheet = nil;
    }
    return self;
}

- (void) dealloc {
    if(securitySheet) {
        [securitySheet release];
    }
    [registrationStateImage release];
    [registrationStateLabel release];
    [callQualityImage release];
    [callSecurityImage release];
    [callSecurityButton release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [callQualityTimer invalidate];
    [callQualityTimer release];
    [super dealloc];
}


#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Set callQualityTimer
	callQualityTimer = [NSTimer scheduledTimerWithTimeInterval:1 
                                                        target:self 
                                                      selector:@selector(callQualityUpdate) 
                                                      userInfo:nil 
                                                       repeats:YES];
    
    // Set callQualityTimer
	callSecurityTimer = [NSTimer scheduledTimerWithTimeInterval:1 
                                                        target:self 
                                                      selector:@selector(callSecurityUpdate) 
                                                      userInfo:nil 
                                                       repeats:YES];
    
    // Set observer
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(registrationUpdate:) 
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
    
    [callQualityImage setHidden: true];
    [callSecurityImage setHidden: true];
    //Get the balance
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    UserAccount *afriCallUserBal= [[UserAccount alloc] init];
    afriCallUserBal.email = appDelegate.afriCallUser.email;
    afriCallUserBal.firsPasswd=appDelegate.afriCallUser.firsPasswd;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *email=[defaults objectForKey:@"email"];
    NSString *firsPasswd=[defaults objectForKey:@"firsPasswd"];
    afriCallUserBal.email =email;
    afriCallUserBal.firsPasswd=firsPasswd;
    NSString *post =[[NSString alloc] initWithFormat:@"login=%@&password=%@",email,firsPasswd];
    NSLog(@"PostData: %@",post);
    
    NSURL *url=[NSURL URLWithString:@"https://www.africallshop.com/api/get_balance_ios.php"];
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *response = nil;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSLog(@"Response code: %d", [response statusCode]);
    if ([response statusCode] >=200 && [response statusCode] <300)
    {
        NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
        
        NSLog(@"Response ==> %@", responseData);
        // NSString *debut=[NSString stringWithFormat:@"%@",@"Balance = "];
        //  NSString *temp=[responseData substringWithRange:NSMakeRange([debut length],[responseData length]-[debut length])];
        //  NSLog(@"%@",temp);
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
        //  NSLog(@"%@",jsonData);
        
        NSString *balancetext = [jsonData objectForKey:@"Balance"];
        NSLog(@"%@",balancetext);
        
        if([balancetext length])
        {
            NSLog(@"Balance SUCCESS");
            // [self alertStatus:@"Logged in Successfully." :@"Login Success!"];
            afriCallUserBal.balance=balancetext;
            
        } else {
            
            //NSString *error_msg = (NSString *) [jsonData objectForKey:@"error_message"];
            //[self alertStatus:error_msg :@"Login Failed!"];
        }
        
    } else {
        if (error) NSLog(@"Error: %@", error);
        //  [self alertStatus:@"Connection Failed" :@"Login Failed!"];
    }
    [balance setTextColor:LINPHONE_MAIN_COLOR];

    [balance setText:afriCallUserBal.balance];
    
    // Update to default state
    LinphoneProxyConfig* config = NULL;
    if([LinphoneManager isLcReady])
        linphone_core_get_default_proxy([LinphoneManager getLc], &config);
    [self proxyConfigUpdate: config];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self  
                                                    name:kLinphoneRegistrationUpdate
                                                  object:nil];
    
    if(callQualityTimer != nil) {
        [callQualityTimer invalidate];
        callQualityTimer = nil;
    }
    if(callSecurityTimer != nil) {
        [callSecurityTimer invalidate];
        callSecurityTimer = nil;
    }
}


#pragma mark - Event Functions

- (void)registrationUpdate: (NSNotification*) notif {  
    LinphoneProxyConfig* config = NULL;
    linphone_core_get_default_proxy([LinphoneManager getLc], &config);
    [self proxyConfigUpdate:config];
}


#pragma mark - 

- (void)proxyConfigUpdate: (LinphoneProxyConfig*) config {
    LinphoneRegistrationState state;
    NSString* message = nil;
    UIImage* image = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *afriCallUserDisplayName= [defaults objectForKey:@"DisplayName"];
    
    if (config == NULL) {
        state = LinphoneRegistrationNone;
        if(![LinphoneManager isLcReady] || linphone_core_is_network_reachable([LinphoneManager getLc]))
        {
        message = NSLocalizedString(@"No AfriCallShop account configured", nil);
        UIAlertView* infoView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information",nil)
                                                           message:NSLocalizedString(@"Can you please log out and try log on again?",nil)
                                                          delegate:nil
                                                 cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                 otherButtonTitles:nil,nil];
        [infoView show];
        }
        else
            message = NSLocalizedString(@"Network down", nil);
    } else {
        state = linphone_proxy_config_get_state(config);
    
        switch (state) {
            case LinphoneRegistrationOk: 
                message = afriCallUserDisplayName; break;
            case LinphoneRegistrationNone: 
            case LinphoneRegistrationCleared:
                message =  NSLocalizedString(@"Not registered", nil); break;
            case LinphoneRegistrationFailed: 
                message =  NSLocalizedString(@"Registration failed", nil); break;
            case LinphoneRegistrationProgress: 
                message =  NSLocalizedString(@"Registration in progress", nil); break;
            default: break;
        }
    }

    registrationStateLabel.hidden = NO;
    switch(state) {
        case LinphoneRegistrationFailed:
            registrationStateImage.hidden = NO;
            image = [UIImage imageNamed:@"led_error.png"];
            break;
        case LinphoneRegistrationCleared:
        case LinphoneRegistrationNone:
            registrationStateImage.hidden = NO;
            image = [UIImage imageNamed:@"led_disconnected.png"];
            break;
        case LinphoneRegistrationProgress:
            registrationStateImage.hidden = NO;
            image = [UIImage imageNamed:@"led_inprogress.png"];
            break;
        case LinphoneRegistrationOk:
            registrationStateImage.hidden = NO;
            image = [UIImage imageNamed:@"led_connected.png"];
            break;
    }
    [registrationStateLabel setText:message];
    [registrationStateImage setImage:image];
}


#pragma mark - 

- (void)callSecurityUpdate {
    BOOL pending = false;
    BOOL security = true;
    
    if(![LinphoneManager isLcReady]) {
        [callSecurityImage setHidden:true];
        return;
    }
    const MSList *list = linphone_core_get_calls([LinphoneManager getLc]);
    if(list == NULL) {
        if(securitySheet) {
            [securitySheet dismissWithClickedButtonIndex:securitySheet.destructiveButtonIndex animated:TRUE];
        }
        [callSecurityImage setHidden:true];
        return;
    }
    while(list != NULL) {
        LinphoneCall *call = (LinphoneCall*) list->data;
        LinphoneMediaEncryption enc = linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
        if(enc == LinphoneMediaEncryptionNone)
            security = false;
        else if(enc == LinphoneMediaEncryptionZRTP) {
            if(!linphone_call_get_authentication_token_verified(call)) {
                pending = true;
            }
        }
        list = list->next;
    }
    
    if(security) {
        if(pending) {
            [callSecurityImage setImage:[UIImage imageNamed:@"security_pending.png"]];
        } else {
            [callSecurityImage setImage:[UIImage imageNamed:@"security_ok.png"]];
        }
    } else {
        [callSecurityImage setImage:[UIImage imageNamed:@"security_ko.png"]];
    }
    [callSecurityImage setHidden: false];
}

- (void)callQualityUpdate { 
    UIImage *image = nil;
    if([LinphoneManager isLcReady]) {
        LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
        if(call != NULL) {
            //FIXME double check call state before computing, may cause core dump
			float quality = linphone_call_get_average_quality(call);
            if(quality < 1) {
                image = [UIImage imageNamed:@"call_quality_indicator_0.png"];
            } else if (quality < 2) {
                image = [UIImage imageNamed:@"call_quality_indicator_1.png"];
            } else if (quality < 3) {
                image = [UIImage imageNamed:@"call_quality_indicator_2.png"];
            } else {
                image = [UIImage imageNamed:@"call_quality_indicator_3.png"];
            }
        }
    }
    if(image != nil) {
        [callQualityImage setHidden:false];
        [callQualityImage setImage:image];
    } else {
        [callQualityImage setHidden:true];
    }
}


#pragma mark - Action Functions
- (IBAction)topUp:(id)sender
{
    UserAccount *afriCallUserBal= [[UserAccount alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *email=[defaults objectForKey:@"email"];
    NSString *firsPasswd=[defaults objectForKey:@"firsPasswd"];
    afriCallUserBal.email =email;
    afriCallUserBal.firsPasswd=firsPasswd;
    NSString *urlstring = [NSString stringWithFormat:@"https://www.africallshop.com/api/add_solde.php?login=%@&password=%@",email,firsPasswd];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlstring]];
}
- (IBAction)doSecurityClick:(id)sender {
    if([LinphoneManager isLcReady] && linphone_core_get_calls_nb([LinphoneManager getLc])) {
        LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
        if(call != NULL) {
            LinphoneMediaEncryption enc = linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
            if(enc == LinphoneMediaEncryptionZRTP) {
                bool valid = linphone_call_get_authentication_token_verified(call);
                NSString *message = nil;
                if(valid) {
                    message = NSLocalizedString(@"Remove trust in the peer?",nil);
                } else {
                    message = [NSString stringWithFormat:NSLocalizedString(@"Confirm the following SAS with the peer:\n%s",nil),
                               linphone_call_get_authentication_token(call)];
                }
                if(securitySheet == nil) {
                    securitySheet = [[DTActionSheet alloc] initWithTitle:message];
                    [securitySheet addButtonWithTitle:NSLocalizedString(@"Ok",nil) block:^(){
                        linphone_call_set_authentication_token_verified(call, !valid);
                        [securitySheet release];
                        securitySheet = nil;
                    }];
                    
                    [securitySheet addDestructiveButtonWithTitle:NSLocalizedString(@"Cancel",nil) block:^(){
                        [securitySheet release];
                        securitySheet = nil;
                    }];
                    [securitySheet showInView:[PhoneMainView instance].view];
                }
            }
        }
    }
}


#pragma mark - TPMultiLayoutViewController Functions

- (NSDictionary*)attributesForView:(UIView*)view {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
    [attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
    [attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
    [attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];
    
    return attributes;
}

- (void)applyAttributes:(NSDictionary*)attributes toView:(UIView*)view {
    view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
    view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
    view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}

@end
