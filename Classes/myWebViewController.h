//
//  myWebViewController.h
//  linphone
//
//  Created by Abdel Karim on 23/11/13.
//
//

#import <UIKit/UIKit.h>

@interface myWebViewController : UIViewController <UIWebViewDelegate> 
@property (nonatomic, retain) IBOutlet UIWebView *licensesView;
@property (nonatomic, retain) IBOutlet UIView *contentView;
@end
