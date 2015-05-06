//
//  ImagePicker.m
//
//
//  Created by Raphael Pinto on 31/01/2014.
//
// The MIT License (MIT)
// Copyright (c) 2014 Raphael Pinto.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "ImagePicker.h"


#define kImagePickingActionSheetTag 5000


@implementation ImagePicker



@synthesize mEditable;
@synthesize mTryUseFrontCamera;
@synthesize mDeletePicture;
@synthesize mImageLink;
@synthesize mIsHiddenDeleteButton;



#pragma mark -
#pragma mark Object Life Cycle Methods



- (void)dealloc
{
    [_mImage release];
    _mImagePickerController.delegate = nil;
    [_mImagePickerController release];
    [mImageLink release];
    [super dealloc];
}



#pragma mark -
#pragma mark Public Methods



- (void)pickImageFromRect:(CGRect)_FromRect
                   inView:(UIView*)_View
{
    if (!_mDelegate)
    {
        return;
    }
    
    UIViewController* lViewController = [_mDelegate viewControllerToDisplayImagePicker:self];
    
    if (lViewController.view.window)
    {
        UIActionSheet* lActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:nil
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:nil];
        
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            [lActionSheet addButtonWithTitle:NSLocalizedString(@"TakeAPicture", @"")];
        }
        
        [lActionSheet addButtonWithTitle:NSLocalizedString(@"FromLibrary", @"")];
        
        [lActionSheet addButtonWithTitle:NSLocalizedString(@"Paste", @"")];
        
        
        if ((self.mImage || self.mImageLink) && !mIsHiddenDeleteButton)
        {
            [lActionSheet addButtonWithTitle:NSLocalizedString(@"Delete", @"")];
        }
        
        [lActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
        lActionSheet.cancelButtonIndex = lActionSheet.numberOfButtons - 1;
        lActionSheet.tag = kImagePickingActionSheetTag;
        
        
        [lActionSheet showFromRect:CGRectMake(0, _FromRect.origin.y, _FromRect.size.width,
                                              _FromRect.size.height)
                            inView:_View
                          animated:YES];
        
        [lActionSheet release] ;
    }
}



#pragma mark -
#pragma mark UIAction Sheet Delegate Methods



- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag != kImagePickingActionSheetTag)
    {
        return;
    }
    
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        [self.mDelegate imagePickerCancel:self];
        return;
    }
    
    NSString* buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if([buttonTitle isEqualToString:NSLocalizedString(@"FromLibrary", nil)])
    {
        [self chooseFromAlbum];
    }
    else if([buttonTitle isEqualToString:NSLocalizedString(@"TakeAPicture", nil)])
    {
        [self chooseFromCamera];
    }
    else if([buttonTitle isEqualToString:NSLocalizedString(@"ImageLink", nil)])
    {
        UIAlertView* lAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PasteImageURL", @"")
                                                             message:nil
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                   otherButtonTitles:nil];
        lAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        lAlertView.tag = 212;
        [lAlertView show];
        [lAlertView release];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"Paste", @"")])
    {
        UIImage* lImage = [UIPasteboard generalPasteboard].image;
        
        if (lImage)
        {
            self.mImage = [UIPasteboard generalPasteboard].image;
            self.mImageLink = nil;
            [self.mDelegate imagePicker:self DidPasteAPicture:self.mImage];
        }
        else
        {
            UIAlertView* lAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ForbiddenAction", @"")
                                                                 message:NSLocalizedString(@"CopyAnImageBeforePasting", @"")
                                                                delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                       otherButtonTitles:nil];
            [lAlertView show];
            [lAlertView release];
        }
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"Delete", nil)])
    {
        self.mImage = nil;
        self.mImageLink = nil;
        [_mDelegate imagePickerDeleteImage:self];
        self.mImage = nil;
        mDeletePicture = YES;
    }
}



#pragma mark -
#pragma mark UI Alert View Delegate Methods



- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 212)
    {
        UITextField* lTextField = [alertView textFieldAtIndex:0];
        
        if ([lTextField.text length] == 0)
        {
            return;
        }
        
        self.mImage = nil;
        self.mImageLink = lTextField.text;
        
        
        if ([self.mImageLink length] > 0 && [self.mDelegate respondsToSelector:@selector(imagePicker:DidEnterAPictureLink:)])
        {
            [self.mDelegate imagePicker:self DidEnterAPictureLink:lTextField.text];
        }
        else if ([self.mImageLink length])
        {
            [self.mDelegate imagePickerCancel:self];
        }
    }
}



#pragma mark -
#pragma mark Data Management Methods



- (void)chooseFromAlbum
{
    if (!self.mImagePickerController)
    {
        UIImagePickerController* lUIImagePickerController = [[UIImagePickerController alloc] init];
        self.mImagePickerController = lUIImagePickerController;
        [lUIImagePickerController release];
        
        self.mImagePickerController.delegate = self;
    }
    
    self.mImagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
	self.mImagePickerController.allowsEditing  = self.mEditable;
    
	self.mImagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical ;

    [[_mDelegate viewControllerToDisplayImagePicker:self] presentViewController:self.mImagePickerController animated:false completion:nil];
}


- (void)chooseFromCamera
{
    if (!self.mImagePickerController)
    {        
        UIImagePickerController* lUIImagePickerController = [[UIImagePickerController alloc] init];
        self.mImagePickerController = lUIImagePickerController;
        [lUIImagePickerController release];
        
        self.mImagePickerController.delegate = self;
    }
    
    self.mImagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    if (mTryUseFrontCamera)
    {
        self.mImagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    
    self.mImagePickerController.allowsEditing  = self.mEditable;
    self.mImagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [[_mDelegate viewControllerToDisplayImagePicker:self] presentViewController:self.mImagePickerController animated:false completion:nil];

}



#pragma mark -
#pragma mark Image Picker Delegate Methods



- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (self.mEditable)
    {
        self.mImage = [info valueForKey:UIImagePickerControllerEditedImage];
    }
    else
    {
        self.mImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    }
    
    if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)
    {
        [self.mDelegate imagePicker:self DidFinishPickingImageFromGallery:self.mImage];
    }
    else if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        [self.mDelegate imagePicker:self DidFinishPickingImageFromCamera:self.mImage];
    }
    
	[picker dismissViewControllerAnimated:YES completion:nil];
    self.mImagePickerController = nil;
    self.mImageLink = nil;
    self.mDeletePicture = NO;
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[picker dismissViewControllerAnimated:YES completion:nil];
    self.mImagePickerController = nil;
}


@end
