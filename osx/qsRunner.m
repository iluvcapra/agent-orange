#import "qsRunner.h"

#define NSTRUE	[NSNumber numberWithBool:YES]
#define NSFALSE	[NSNumber numberWithBool:NO]
#define NSINT(x)	[NSNumber numberWithInt:x]
#define NSDBL(x)	[NSNumber numberWithDouble:x]

@implementation qsRunner

+(void)initialize
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary]; 
	[defaults setObject:NSTRUE		forKey:@"AO_InterpretTags"];
	[defaults setObject:NSFALSE		forKey:@"AO_PrintFrames"];
	[defaults setObject:NSTRUE		forKey:@"AO_OpenWhenFinished"];
	[defaults setObject:NSTRUE		forKey:@"AO_PrintChannelNumbers"];
	[defaults setObject:NSTRUE		forKey:@"AO_DeCamelizeRegionNames"];
	[defaults setObject:NSDBL(8)	forKey:@"AO_StripsPerPage"];
	[defaults setObject:@"LETTER"	forKey:@"AO_PaperSize"];
	[defaults setObject:NSINT(0)	forKey:@"AO_ShadeOptionIndex"];
	[defaults setObject:NSDBL(1)	forKey:@"AO_BlendDuration"];
	[defaults setObject:@"1"		forKey:@"AO_FirstChannelNumber"];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	
	[qsRunner setKeys:[NSArray arrayWithObject:@"inFile"] 
		triggerChangeNotificationsForDependentKey:@"inFileSelected"];
}

-(id)init
{
	if (self = [super init])
	{
	[[NSNotificationCenter defaultCenter] addObserver: self 
											 selector: @selector(checkToolStatus:) 
												 name: NSTaskDidTerminateNotification 
											   object: nil];
		tracks = [[NSMutableArray array] retain];
		return self;
	}
	else
	{
		[self dealloc];
		return nil;
	}
}

-(void)saveSettingsToPreferences {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	[defs setObject:[self valueForKey:@"paperSize"]
			 forKey:@"AO_PaperSize"];
	[defs setObject:[self valueForKey:@"stripsPerPage"]
			 forKey:@"AO_StripsPerPage"];
	[defs setObject:[self valueForKey:@"blendDuration"]
			 forKey:@"AO_BlendDuration"];
	[defs setObject:[self valueForKey:@"interpretTags"]
			 forKey:@"AO_InterpretTags"];
	[defs setObject:[self valueForKey:@"printFrames"]
			 forKey:@"AO_PrintFrames"];
	[defs setObject:[self valueForKey:@"openWhenFinished"]
			 forKey:@"AO_OpenWhenFinished"];
	[defs setObject:[self valueForKey:@"shadeOptionIndex"]
			 forKey:@"AO_ShadeOptionIndex"];
	[defs setObject:[self valueForKey:@"firstChannelNumber"] 
			 forKey:@"AO_FirstChannelNumber"];
	[defs setObject:[self valueForKey:@"printChannelNumbers"] 
			 forKey:@"AO_PrintChannelNumbers"];
	[defs setObject:[self valueForKey:@"deCamelizeRegionNames"]
			 forKey:@"AO_DeCamelizeRegionNames"];
}

-(void)dealloc
{
	[tracks release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(void)awakeFromNib
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	[self setValue:@"Ready for text file." forKey:@"statusMessage"];
	[self setValue:[defs objectForKey:@"AO_PaperSize"] forKey:@"paperSize"];
	[self setValue:[defs objectForKey:@"AO_StripsPerPage"] forKey:@"stripsPerPage"];
	[self setValue:[defs objectForKey:@"AO_BlendDuration"] forKey:@"blendDuration"];
	[self setValue:[defs objectForKey:@"AO_InterpretTags"] forKey:@"interpretTags"];
	[self setValue:[defs objectForKey:@"AO_PrintFrames"] forKey:@"printFrames"];
	[self setValue:[defs objectForKey:@"AO_OpenWhenFinished"] forKey:@"openWhenFinished"];
	[self setValue:[defs objectForKey:@"AO_ShadeOptionIndex"] forKey:@"shadeOptionIndex"];
	[self setValue:[defs objectForKey:@"AO_FirstChannelNumber"] forKey:@"firstChannelNumber"];
	[self setValue:[defs objectForKey:@"AO_PrintChannelNumbers"] forKey:@"printChannelNumbers"];
	[self setValue:[defs objectForKey:@"AO_DeCamelizeRegionNames"] forKey:@"deCamelizeRegionNames"];
	
	[self setValue:NSFALSE forKey:@"qsRunning"];
	[self setValue:@"agent-orange.rb" forKey:@"tool"];
}

-(void)setPaperSize:(NSString *)aSize
{
	[paperSize release];
	paperSize = aSize;
	[paperSize retain];
	
	[self willChangeValueForKey:@"stripsPerPage"];
	
	if ([paperSize isEqual:@"TABLOID"])
		stripsPerPage = 16;
	else if ([paperSize isEqual:@"LEGAL"])
		stripsPerPage = 12;
	else
		stripsPerPage = 8;
	
	[self didChangeValueForKey:@"stripsPerPage"];
}

-(IBAction)selectInFile:(id)sender
{
	NSOpenPanel *p = [NSOpenPanel openPanel];
	
	[p setMessage:@"Select a text file:"];
	[p setAllowsMultipleSelection:NO];
	
	[p beginSheetForDirectory: nil
						 file: nil
			   modalForWindow: cuesheetWindow
				modalDelegate: self
			   didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
				  contextInfo: nil];
}


-(IBAction)createText:(id)sender
{
	[self setValue:@"ao-qc.rb" forKey:@"tool"];	
	NSSavePanel *p = [NSSavePanel savePanel];
	
	[p setMessage:@"Save a processed text file:"];
	[p beginSheetForDirectory: nil
						 file: [[[inFile stringByDeletingPathExtension] lastPathComponent] stringByAppendingPathExtension:@"txt"]
			   modalForWindow: cuesheetWindow
				modalDelegate: self
			   didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:) 
				  contextInfo: nil];	
}

-(IBAction)createPDF:(id)sender
{
	[self setValue:@"agent-orange.rb" forKey:@"tool"];	
	NSSavePanel *p = [NSSavePanel savePanel];
	
	[p setMessage:@"Save a new PDF file of this cuesheet:"];
	[p beginSheetForDirectory: nil
						 file: [[[inFile stringByDeletingPathExtension] lastPathComponent] stringByAppendingPathExtension:@"pdf"]
			   modalForWindow: cuesheetWindow
				modalDelegate: self
			   didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:) 
				  contextInfo: nil];
}


- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
	{
		
		NSString *theFile = [[sheet filenames] objectAtIndex:0];
		
		NSTask *titleGetter = [NSTask new];
		NSPipe *so = [NSPipe pipe];
		[self setValue:@"ao-info.rb" forKey:@"tool"];
		[titleGetter setLaunchPath:[self toolPath]];
		[titleGetter setArguments:[NSArray arrayWithObjects: theFile,nil]];
		[titleGetter setStandardOutput:so];
		[titleGetter launch];
		[titleGetter waitUntilExit];
		
		int termVal = [titleGetter terminationStatus];
		
		if (termVal != 0) {
			NSAlert *parseError = [NSAlert alertWithMessageText:@"Error Reading Text File" 
												  defaultButton:@"OK"
												alternateButton:nil
													otherButton:nil
									  informativeTextWithFormat:@"Agent Orange was unable to recognize the file you provided for \
input.  Agent Orange is only capable of reading text exports in the \
format used by Pro Tools.  Make sure you are inputting the correct \
kind of file, and try again."];
			[parseError setAlertStyle: NSCriticalAlertStyle];
			[parseError runModal];
		} else {
			[self setValue:theFile forKey:@"inFile"];
			[self setValue:NSTRUE forKey:@"inFileSelected"];
			
			[self setValue:@"File selected, ready to create output." forKey:@"statusMessage"];
			
			[tracks removeAllObjects];
			
			NSString *outputString = [[NSString alloc] initWithData:[[so fileHandleForReading] availableData] 
														   encoding:NSUTF8StringEncoding];

			NSArray *lines = [outputString componentsSeparatedByString:@"\n"]; 
			
			[self setValue:[[lines objectAtIndex:1] substringFromIndex:23] forKey:@"title"];	
			
			int i;
			NSString *thisLine;
			[self willChangeValueForKey:@"tracks"];
			
			for (i = 4; i < [lines count] && (thisLine = [lines objectAtIndex:i]); i++)
			{	
				//NSLog(@"reading track name: %@", [thisLine substringFromIndex:23]);
				if ([thisLine length] > 23)
				{
					qsTrack *aTrack = [qsTrack new];
					[aTrack setValue:[thisLine substringFromIndex:23] forKey:@"trackName"];
					[aTrack setValue:NSTRUE forKey:@"showTrack"];
					[tracks addObject:aTrack];
				}
			}
			
			[self didChangeValueForKey:@"tracks"];

			
			
			inFileSelected = YES;			
		}
	}
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
	{
		[self setValue:[sheet filename] forKey:@"outFile"];
		[self runScript];	
	}
}


-(void)runScript
{
	if ([tool isEqual:@"agent-orange.rb"])
		[self setValue:@"Beginning PDF Generation..." forKey:@"statusMessage"];
	else
		[self setValue:@"Interpreting text file..." forKey:@"statusMessage"];
	
	if ([self toolArguments]) {
		qsTask = [[NSTask new] retain];
		//NSPipe *errorPipe = [NSPipe pipe];

		[qsTask setLaunchPath:		[self toolPath]];
		[qsTask setArguments:		[self toolArguments]];
		//[qsTask setStandardError:	errorPipe ];
		[qsTask launch];
		[self setValue:[NSNumber numberWithBool:YES] forKey:@"qsRunning"];		
		[self setValue:@"Generating Cuesheet..." forKey:@"statusMessage"];
		[self saveSettingsToPreferences];
		NSLog(@"agent orange: running %@ %@", [self toolPath],[self toolArguments]);
		
	}
}

-(void)checkToolStatus:(NSNotification *)aNotification
{
	NSLog(@"Notification was received: %@", aNotification);
	if (![qsTask isRunning] && [aNotification object] == qsTask)
	{
		[self setValue:[NSNumber numberWithBool:NO] forKey:@"qsRunning"];
		int status = [[aNotification object] terminationStatus];
		NSBeep();
		
		NSAlert *doneMessage = nil;
		
		if (status == 0)
		{
			if (openWhenFinished)
			{
				[self setValue:@"Opening PDF..." forKey:@"statusMessage"];
				if ([[NSWorkspace sharedWorkspace] openFile:outFile])
					[self setValue:@"Cuesheet generation complete" forKey:@"statusMessage"];
				else
				{
					[self setValue:@"An error occurred opening the PDF" forKey:@"statusMessage"];
					doneMessage = [NSAlert alertWithMessageText:@"Error Opening PDF" 
												  defaultButton:@"OK"
												alternateButton:nil
													otherButton:nil
									  informativeTextWithFormat:
	@"Agent Orange was unable to order the Finder to open the PDF file. \
	You may not have a PDF reader installed on this computer, or there may be a problem with the volume \
	to which you saved the PDF."];
						[doneMessage setAlertStyle: NSCriticalAlertStyle];	
				}
				
			} else {
				[self setValue:@"PDF Generation Complete." forKey:@"statusMessage"];	
				 doneMessage = [NSAlert alertWithMessageText:@"Cuesheet generation complete" 
													   defaultButton:@"OK" 
													 alternateButton:nil 
														 otherButton:nil 
										   informativeTextWithFormat:@""];
			}
		}
		else if (status == 17001)
		{
			doneMessage = [NSAlert alertWithMessageText:@"Error Loading qs Libraries" 
										  defaultButton:@"OK"
										alternateButton:nil
											otherButton:nil
							informativeTextWithFormat:
	@"Agent Orange depends on certain software to be \
	installed on your computer.  An error occurred while \
	resolving these dependencies.  Check the documentation \
	for possible solutions."];
			[doneMessage setAlertStyle: NSCriticalAlertStyle];
		}
		else
		{
			doneMessage = [NSAlert alertWithMessageText:@"Error Generating PDF" 
										  defaultButton:@"OK"
										alternateButton:nil
											otherButton:nil
							  informativeTextWithFormat:
				@"An error occurred while generating the PDF file."];
			[self setValue:@"PDF Generation error." forKey:@"statusMessage"];
			[doneMessage setAlertStyle: NSCriticalAlertStyle];
		}
		
		[qsTask release];
		
		if (doneMessage) [doneMessage beginSheetModalForWindow: cuesheetWindow
							 modalDelegate: self
							didEndSelector: @selector(alertDidEnd:returnCode:contextInfo:) 
							   contextInfo: nil];
	}
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	
}

-(NSArray *)paperSizes
{
	return [NSArray arrayWithObjects:@"TABLOID" , @"LEGAL" , @"LETTER" , nil ];
}

-(NSString *)toolPath
{
	NSString *toolResourcePath = [NSString stringWithFormat:@"%@/agent-orange-1_4_0/bin/%@", [[NSBundle mainBundle] resourcePath] , tool];
	NSLog(@"Tried to launch %@",toolResourcePath);
	return toolResourcePath;
}

-(NSArray *)toolArguments
{
	if (inFile && outFile) {
		NSMutableArray *retAry = [NSMutableArray arrayWithObjects: 
			@"-o" , outFile , 
			@"-b" , [[self valueForKey:@"blendDuration"] stringValue] , nil];
			
		if ([tool isEqual:@"agent-orange.rb"]) {
			[retAry addObjectsFromArray:[NSArray arrayWithObjects:
				@"-p" , paperSize , 
				@"-t" , title , 
				@"-s" , [[self valueForKey:@"stripsPerPage"] stringValue] , nil]] ;
			
			switch (shadeOptionIndex)
			{
				case 1:
					[retAry addObject:@"--shade-nothing"];
					break;
			}
			
			if (printFrames) [retAry addObject: @"-f"];
			
			if (deCamelizeRegionNames) [retAry addObject:@"-D"];
			
			if (!printChannelNumbers) [retAry addObject:@"-0"];
			
			int i;
			qsTrack *track;
			for (i = 0; i < [tracks count]; i++)
			{
				track = [tracks objectAtIndex:i];
				if ([[track valueForKey:@"showTrack"] isEqual:NSFALSE])
					[retAry addObjectsFromArray:[NSArray arrayWithObjects:@"-e",
						[NSString stringWithFormat:@"%i",i], nil]];
			}
			
			[retAry addObjectsFromArray: [NSArray arrayWithObjects:@"-r", firstChannelNumber, nil]];
		}
		
		if (!interpretTags) [retAry addObject: @"-i"];
		
		[retAry	addObject: inFile];
		return [NSArray arrayWithArray: retAry];
	}
	else return [NSArray array];
}

-(IBAction)launchHelpWebpage:(id)sender
{
	[[NSWorkspace sharedWorkspace] 
	openURL:[NSURL URLWithString:@"http://www.soundepartment.com/agent_orange/"]];
}

-(IBAction)launchForumWebpage:(id)sender
{
	[[NSWorkspace sharedWorkspace] 
	openURL:[NSURL URLWithString:@"http://groups.google.com/group/ao-cuesheets?hl=en"]];
}
@end
