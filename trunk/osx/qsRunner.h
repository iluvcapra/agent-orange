/* qsRunner */

#import <Cocoa/Cocoa.h>
#import "qsTrack.h"

@interface qsRunner : NSObject
{
	NSString *inFile;
	NSString *outFile;
	NSString *title;
	NSString *paperSize;
	
	NSString *tool;
	
	NSMutableArray *tracks;		//
	
	int shadeOptionIndex;
	
	NSString *statusMessage;
	
	NSString  *firstChannelNumber;	//
	double stripsPerPage;
	double blendDuration;
	
	BOOL interpretTags;
	BOOL printFrames;
	BOOL openWhenFinished;
	BOOL printChannelNumbers;
	BOOL deCamelizeRegionNames;
    BOOL printMutedRegions;
	
	BOOL inFileSelected;
	BOOL qsRunning;
	
	NSTask *qsTask;
	
	IBOutlet NSWindow *cuesheetWindow;

}

-(IBAction)selectInFile:(id)sender;
-(IBAction)createPDF:(id)sender;
-(IBAction)createText:(id)sender;
-(IBAction)launchHelpWebpage:(id)sender;
-(IBAction)launchForumWebpage:(id)sender;

// NSPanel delegate methods
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

-(void)runScript;

-(NSArray *)paperSizes;

-(void)setPaperSize:(NSString *)aSize;

-(NSString *)toolPath;
-(NSArray *)toolArguments;

@end
