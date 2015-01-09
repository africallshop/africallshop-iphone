/* HistoryTableViewController.m
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */     

#import "HistoryTableViewController.h"
#import "UIHistoryCell.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UACellBackgroundView.h"
#import "UILinphone.h"
#import "Utils.h"

@implementation HistoryTableViewController

@synthesize missedFilter;

#pragma mark - Lifecycle Functions

- (void)initHistoryTableViewController {
    callLogs = [[NSMutableArray alloc] init];
    missedFilter = false;
}

- (id)init {
    self = [super init];
    if (self) {
		[self initHistoryTableViewController];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
		[self initHistoryTableViewController];
	}
    return self;
}	

- (void)dealloc {
    [callLogs release];
    [super dealloc];
}


#pragma mark - ViewController Functions 

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadData)
                                                 name:kLinphoneAddressBookUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(coreUpdateEvent:)
                                                 name:kLinphoneCoreUpdate
                                               object:nil];
    [self loadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneAddressBookUpdate
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneCoreUpdate
                                                  object:nil];
    
}


#pragma mark - Event Functions

- (void)coreUpdateEvent:(NSNotification*)notif {
    // Invalid all pointers
    [self loadData];
}


#pragma mark - Property Functions

- (void)setMissedFilter:(BOOL)amissedFilter {
    if(missedFilter == amissedFilter) {
        return;
    }
    missedFilter = amissedFilter;
    [self loadData];
}


#pragma mark - UITableViewDataSource Functions

- (void)loadData {
    [callLogs removeAllObjects];
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
    
    NSURL *url=[NSURL URLWithString:@"https://www.africallshop.com/api/get_calls_ios.php"];
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *response = nil;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSLog(@"Response code: %d", [response statusCode]);
    if ([response statusCode] >=200 && [response statusCode] <300)
    {
        NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
        
        NSLog(@"Response ==> %@", responseData);
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
        NSLog(@"%@",jsonData);
        
        for ( NSDictionary* dic in jsonData)
        {
            //Save message in database
            AfriCallShopCalLog *log = [[AfriCallShopCalLog alloc] init];
            if ([dic objectForKey:@"duree_appel"])
                [log setCallDuration:[dic objectForKey:@"duree_appel"]];
            else
                [log setCallDuration:@""];
            
            [log setNom_contact:[dic objectForKey:@"nom_contact"]];
            [log setCalledCountry:[dic objectForKey:@"pays_appele"]];
            [log setTo:[dic objectForKey:@"numero_appele"]];
            [log setRate:[dic objectForKey:@"prix_appele"]];
            
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *calldate = [df dateFromString:[dic objectForKey:@"date_appel"]];
            
            [log setCallDate:calldate];
            
            // break;
            [callLogs addObject:log];
        }
    }
    [[self tableView] reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [callLogs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellId = @"UIHistoryCell";
    UIHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
    if (cell == nil) {
        cell = [[[UIHistoryCell alloc] initWithIdentifier:kCellId] autorelease];
        // Background View
        UACellBackgroundView *selectedBackgroundView = [[[UACellBackgroundView alloc] initWithFrame:CGRectZero] autorelease];
        cell.selectedBackgroundView = selectedBackgroundView;
        [selectedBackgroundView setBackgroundColor:LINPHONE_TABLE_CELL_BACKGROUND_COLOR];
    }
    
   // LinphoneCallLog *log = [[callLogs objectAtIndex:[indexPath row]] pointerValue];
   // [cell setCallLog:log];
    
    AfriCallShopCalLog *log = [callLogs objectAtIndex:[indexPath row]] ;
    [cell setAfricallLog:log];
	
    return cell;
}


#pragma mark - UITableViewDelegate Functions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
    //LinphoneCallLog *callLog = [[callLogs objectAtIndex:[indexPath row]] pointerValue];
    AfriCallShopCalLog *callLog = [callLogs objectAtIndex:[indexPath row]] ;
    //	LinphoneAddress* addr;
    //	if (linphone_call_log_get_dir(callLog) == LinphoneCallIncoming) {
    //		addr = linphone_call_log_get_from(callLog);
    //	} else {
    //		addr = linphone_call_log_get_to(callLog);
    //	}
    
    NSString* displayName = nil;
    NSString* address = nil;
    address=callLog.to;
    NSString *normalizedSipAddress = [FastAddressBook normalizeSipURI:address];
    ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:normalizedSipAddress];
    
    if(contact) {
        displayName = [FastAddressBook getContactDisplayName:contact];
    }
    
//    if(addr != NULL) {
//        BOOL useLinphoneAddress = true;
//        // contact name 
//        char* lAddress = linphone_address_as_string_uri_only(addr);
//        if(lAddress) {
//            address = [NSString stringWithUTF8String:lAddress];
//            NSString *normalizedSipAddress = [FastAddressBook normalizeSipURI:address];
//            ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:normalizedSipAddress];
//            if(contact) {
//                displayName = [FastAddressBook getContactDisplayName:contact];
//                useLinphoneAddress = false;
//            }
//            ms_free(lAddress);
//        }
//        if(useLinphoneAddress) {
//            const char* lDisplayName = linphone_address_get_display_name(addr);
//            if (lDisplayName)
//                displayName = [NSString stringWithUTF8String:lDisplayName];
//        }
//    }
    
    if(address != nil) {
        // Go to dialer view
        DialerViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]], DialerViewController);
        if(controller != nil) {
            [controller call:address displayName:displayName];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Detemine if it's in editing mode
    if (self.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath  {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        LinphoneCallLog *callLog = [[callLogs objectAtIndex:[indexPath row]] pointerValue];
        linphone_core_remove_call_log([LinphoneManager getLc], callLog);
        [callLogs removeObjectAtIndex:[indexPath row]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
    }
}

@end

