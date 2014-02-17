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



#pragma mark -
#pragma mark Object Life Cycle Methods



- (void)dealloc
{
    [_mImage release];
    [_mImagePickerController release];
    [super dealloc];
}



#pragma mark -
#pragma mark Public Methods



- (void)pickImage
{
    if (!_mDelegate)
    {
        return;
    }
    UIActionSheet * lActionSheet	= nil;
    NSMutableArray* lButtonArray = [NSMutableArray array];
    
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        if (self.mImage)
        {
            [lButtonArray addObject:NSLocalizedString(@"Delete", nil)];
            lActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"StudioView.choosePicture", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"StudioView.fromAlbum", nil), NSLocalizedString(@"Delete", nil), nil];
        }
        else
        {
            lActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"StudioView.choosePicture", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"StudioView.fromAlbum", nil), nil];
        }
    }
    else
    {
        if (self.mImage)
        {
            [lButtonArray addObject:NSLocalizedString(@"Delete", nil)];
            lActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"StudioView.choosePicture", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"StudioView.fromAlbum", nil), NSLocalizedString(@"StudioView.fromCamera", nil), NSLocalizedString(@"Delete", nil), nil];
        }
        else
        {
            lActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"StudioView.choosePicture", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"StudioView.fromAlbum", nil), NSLocalizedString(@"StudioView.fromCamera", nil), nil];
        }
    }
    
        
    lActionSheet.tag = kImagePickingActionSheetTag;
    
    [lActionSheet showInView:[_mDelegate viewControllerToDisplayImagePicker:self].view];
    
	[lActionSheet release] ;
}



#pragma mark -
#pragma mark UIAction Sheet Delegate Methods



- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		if(buttonIndex == 0)
		{
			[self chooseFromAlbum];
		}
		else if(buttonIndex == 1)
		{
            [self chooseFromCamera];
		}
		else if (buttonIndex == 2 && actionSheet.tag == 1)
		{
			[_mDelegate imagePickerDeleteImage:self];
		}
	}
	else
	{
		if(buttonIndex == 0)
		{
			[self chooseFromAlbum];
		}
		else if(buttonIndex == 1 && actionSheet.tag == 1)
		{
			[_mDelegate imagePickerDeleteImage:self];
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
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[picker dismissViewControllerAnimated:YES completion:nil];
    self.mImagePickerController = nil;
}


@end
