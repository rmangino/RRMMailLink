//
//  RRMMailLinkPlugin.m
//  RRMMailLink
//
//  Created by Reed on 1/1/14.
//  Copyright (c) 2014 Reed Mangino. All rights reserved.
//
//  NOTE: Plugin compatibility:
//
//  Info.plist must contain an array (named SupportedPluginCompatibilityUUIDs) of strings:
//  "Item 0" - "1CD40D64-945D-4D50-B12D-9CD865533506",
//  ...
//
//  You obtain the UUID for any version of Mail.app via:
//      defaults read /Applications/Mail.app/Contents/Info PluginCompatibilityUUID
//
//  The following defaults must be set to enable Mail plugins:
//      defaults write com.apple.mail EnableBundles -bool true
//
//      defaults write com.apple.mail BundleCompatibilityVersion 3  // OS X 10.6
//      defaults write com.apple.mail BundleCompatibilityVersion 4  // OS X 10.7+
//
//  RRMMailLink.mailbundle should be copied into ~/Library/Mail/Bundles
//

#import <objc/runtime.h>
#import "RRMMailLinkPlugin.h"

static NSString* const RRMMVMailBundleName         = @"MVMailBundle";
static NSString* const RRMHyperlinkEditorClassName = @"HyperlinkEditor";

@implementation RRMMailLinkPlugin

+ (void)initialize
{
    [super initialize];
    
    Class mvMailBundleClass = NSClassFromString(RRMMVMailBundleName);
    if (!mvMailBundleClass)
    {
        NSLog(@"%@: Unable to locate MVMailBundle", NSStringFromClass([RRMMailLinkPlugin class]));
    }
    else
    {
        [RRMMailLinkPlugin registerBundle];
        NSLog(@"%@: Successfully loaded bundle", NSStringFromClass([RRMMailLinkPlugin class]));
    }
}

+ (void)registerBundle
{
    if(class_getClassMethod(NSClassFromString(RRMMVMailBundleName), @selector(registerBundle)))
    {
        [NSClassFromString(RRMMVMailBundleName) performSelector:@selector(registerBundle)];
    }
    
    [[self class] setup];
}

// Dummy selector used to quiet the "Unknown selector" warnings in the +setup method
- (void)editLink { NSAssert(FALSE, @"Should never execute!"); }

// Check out https://www.mikeash.com/pyblog/friday-qa-2010-01-29-method-replacement-for-fun-and-profit.html
// for an explaination of how direct override works. In this specific case we can't easily
// use a class category because we don't want to link against Mail.app's private framework.
+ (void)setup
{
    Class hyperLinkEditorClass = NSClassFromString(RRMHyperlinkEditorClassName);
    
    Method originalMethod = class_getInstanceMethod(hyperLinkEditorClass, @selector(editLink));
    
	gOriginalEditLinkMethod = (void *)method_getImplementation(originalMethod);
    
    BOOL methodAdded = class_addMethod(hyperLinkEditorClass,
                                       @selector(editLink),
                                       (IMP)OverrideEditLinkMethod,
                                       method_getTypeEncoding(originalMethod));
    if (!methodAdded)
    {
        method_setImplementation(originalMethod, (IMP)OverrideEditLinkMethod);
    }
}

//------------------------------------------------------------------------------

void (*gOriginalEditLinkMethod)(id, SEL);

//
// Before the link sheet (Edit -> Add Link...) is displayed, determine if there is
// a valid URL on the pasteboard. If there is, copy that url's string into the sheet's
// textfield.
//
// If we add/modify a link in the textfield we automatically click the sheet's ok button to dismiss
// the sheet.
//
static void OverrideEditLinkMethod(id self, SEL _cmd)
{
	gOriginalEditLinkMethod(self, _cmd);
		
    NSTextField* tf = [self valueForKey:@"_linkTextField"];

    NSArray *classes = @[[NSURL class], [NSString class]];
    NSArray *urls = [[NSPasteboard generalPasteboard] readObjectsForClasses:classes
                                                                    options:nil];
    if (urls.count > 0)
    {
        NSURL *theURL = nil;
        
        id pasteboardItem = urls[0];
        if ([pasteboardItem isKindOfClass:[NSURL class]])
        {
            theURL = (NSURL *)pasteboardItem;
        }
        else if ([pasteboardItem isKindOfClass:[NSString class]])
        {
            NSString *urlString = (NSString *)pasteboardItem;
            NSRange range = [urlString rangeOfString:@"://"];
            if (NSNotFound != range.location)
            {
                theURL = [NSURL URLWithString:urlString];
                if (nil == theURL)
                {
                    NSString *encodedURLString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    theURL = [NSURL URLWithString:encodedURLString];
                }
            }
        }
        
        if (nil != theURL)
        {
            if (![tf.stringValue isEqualToString:theURL.absoluteString])
            {
                tf.stringValue = theURL.absoluteString;
                [self controlTextDidChange:nil];
                
                NSButton* okButton = [self valueForKey:@"_okButton"];
                if (okButton)
                {
                    double delayInSeconds = 1.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                        [okButton performClick:self];
                    });
                }
            }
        }
    }
}

@end
