//
//  GraphView.m
//  repWallet
//
//  Created by Alberto Fiore on 3/12/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "GraphView.h"
#import <math.h>
#import <stdio.h>


@implementation GraphView

@synthesize graph;
@synthesize dataForPlot;
@synthesize pointArray;
@synthesize labelsArray;
@synthesize labelsTickLocationsArray;
@synthesize yMin;
@synthesize yMax;


int getUnitOfScale(double maxRange) 
{
    int maxRangeInt = abs(floor(maxRange));
    
    int unitOfScale = 1;
    
    if(maxRangeInt <= 10)
        return unitOfScale;
    
    while(true){
        if(unitOfScale >= maxRangeInt)
            return unitOfScale / 10;
        else
            unitOfScale = 10 * unitOfScale;
    }
}

NSDictionary * getDisplacementForIntermediatePoints(NSNumber * x1, NSNumber * y1, NSNumber * x2, NSNumber * y2, NSNumber * x3, NSNumber * y3) 
{
    
    NSNumber * retX = [NSNumber numberWithFloat:0.0f];
    NSNumber * retY = [NSNumber numberWithFloat:12.0f];
    
    double doubleX1 = [x1 doubleValue];
    double doubleY1 = [y1 doubleValue];
    
    double doubleX2 = [x2 doubleValue];
    double doubleY2 = [y2 doubleValue];
    
    double doubleX3 = [x3 doubleValue];
    double doubleY3 = [y3 doubleValue];
    
//    NSLog(@"getting displacement for points (%f,%f) (%f,%f) (%f,%f)", doubleX1, doubleY1, doubleX2, doubleY2, doubleX3, doubleY3);
    
    if(doubleX1 != doubleX2) {
        
        // retta non verticale
        
        double m1 = (doubleY2 - doubleY1) / (doubleX2 - doubleX1);
        
        double m2 = (doubleY3 - doubleY2) / (doubleX3 - doubleX2);
        
        if(m1 >= 0 && m2 <= 0) {
            
            // /\
            
            retX = [NSNumber numberWithFloat:0.0f];
            retY = [NSNumber numberWithFloat:12.0f];
            
        } else if((m1 < 0 && m2 > 0) || (m1 == 0 && m2 > 0) || (m1 < 0 && m2 == 0)) {
            
             // \/
            
            retX = [NSNumber numberWithFloat:0.0f];
            retY = [NSNumber numberWithFloat:-12.0f];
            
        } else
            ;

    } else {
        // caso che non gestisco (non c'è bisogno)
    }
    
    
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:retX, retY, nil] forKeys:[NSArray arrayWithObjects:@"x", @"y", nil]];
}


NSDictionary * getDisplacementForExtremePoints(NSNumber * x1, NSNumber * y1, NSNumber * x2, NSNumber * y2, BOOL displacementForStartingPoint) 
{
    
    NSNumber * retX = [NSNumber numberWithFloat:0.0f];
    NSNumber * retY = [NSNumber numberWithFloat:12.0f];
    
    double doubleX1 = [x1 doubleValue];
    double doubleY1 = [y1 doubleValue];
    
    double doubleX2 = [x2 doubleValue];
    double doubleY2 = [y2 doubleValue];
    
    
//    NSLog(@"getting displacement for points (%f,%f) (%f,%f)", doubleX1, doubleY1, doubleX2, doubleY2);
    
    if(doubleX1 != doubleX2) {
        
        // retta non verticale
        
        if(displacementForStartingPoint) {
            
            if(doubleY1 > doubleY2 || doubleY1 == doubleY2) {
                
                retX = [NSNumber numberWithFloat:0.0f];
                retY = [NSNumber numberWithFloat:12.0f];
                
            } else if(doubleY1 < doubleY2) {
                
                retX = [NSNumber numberWithFloat:0.0f];
                retY = [NSNumber numberWithFloat:-12.0f];
                
            } else
                ;
            
        } else {
            
            if(doubleY1 > doubleY2) {
                
                retX = [NSNumber numberWithFloat:0.0f];
                retY = [NSNumber numberWithFloat:-12.0f];
                
            } else if(doubleY1 < doubleY2 || doubleY1 == doubleY2) {

                retX = [NSNumber numberWithFloat:0.0f];
                retY = [NSNumber numberWithFloat:12.0f];
                
            } else
                ;
        }
        
    } else {
        // caso che non gestisco (non c'è bisogno)
    }
    
    
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:retX, retY, nil] forKeys:[NSArray arrayWithObjects:@"x", @"y", nil]];
}


# pragma mark - Change orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationPortraitUpsideDown) | (1 << UIInterfaceOrientationLandscapeLeft) | (1 << UIInterfaceOrientationLandscapeRight);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return ((orientation == UIInterfaceOrientationPortrait) ||
            (orientation == UIInterfaceOrientationPortraitUpsideDown) ||
            (orientation == UIInterfaceOrientationLandscapeLeft) ||
            (orientation == UIInterfaceOrientationLandscapeRight));
}


-(id)initWithLabelsAndValues:(NSMutableArray *)data 
{
    self = [super init];
    
    if(self){
        lastSelectedIndex = -1;
        // Create graph
        CPTXYGraph *g = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
        self.graph = g;
        
        // self.pointArray contains the last data inserted
        self.pointArray = [NSMutableArray arrayWithCapacity:[data count]];
        self.labelsTickLocationsArray = [NSMutableArray arrayWithCapacity:[data count]];
        self.labelsArray = [NSMutableArray arrayWithCapacity:[data count]];
        self.yMin = [[data objectAtIndex:0] objectForKey:@"val"];
        self.yMax = self.yMin;
        
        int i = 1; // x di partenza
        
        for(NSMutableDictionary * dict in data){
            NSString * label = [dict objectForKey:@"label"];
            [self.labelsTickLocationsArray addObject:[NSDecimalNumber numberWithInt:i]];
            [self.labelsArray addObject:label];
            // Add some (x, y) data for the graph
            NSNumber * x = [NSNumber numberWithDouble: i];
            NSNumber * y = [dict objectForKey:@"val"];
            if([y doubleValue] < [self.yMin doubleValue])
                self.yMin = [NSNumber numberWithDouble:[y doubleValue]]; 
            else if([y doubleValue] > [self.yMax doubleValue])
                self.yMax = [NSNumber numberWithDouble:[y doubleValue]];
            [self.pointArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
            i++;
        }
        // self.dataForPlot is an array of point arrays
        self.dataForPlot = [NSMutableArray array];
        
        [g release];
    }
        
    return self;
}

-(void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    int unit = getUnitOfScale([self.yMax doubleValue]);
    
//    NSLog(@"scale unit: %i", unit);
    
    // Apply graph theme
    
    CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
    [self.graph applyTheme:theme];
    
    CPTGraphHostingView *hostingView = [[CPTGraphHostingView alloc] initWithFrame: CGRectMake(0.0, 0.0, self.view.bounds.size.width, 370)];
    [self setView:hostingView];
    hostingView.collapsesLayers = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
    hostingView.hostedGraph	= self.graph;
    
    self.graph.paddingLeft = 10.0;
    self.graph.paddingTop = 10.0;
    self.graph.paddingRight = 10.0;
    self.graph.paddingBottom = 10.0;
        
    // Setup plot space
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-1.0) length:CPTDecimalFromDouble(2.0 + [self.pointArray count])];
    double fromYRange = [self.yMin doubleValue] < 0.0 ? [self.yMin doubleValue] - (1.0 * unit) : (-1.0 * unit);
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(fromYRange) length:CPTDecimalFromDouble(1.0 * unit + [self.yMax doubleValue] - fromYRange)];
    
//    NSLog(@"plotSpace.xRange location %f length %f", CPTDecimalDoubleValue([plotSpace.xRange location]), CPTDecimalDoubleValue([plotSpace.xRange length]));
//    NSLog(@"plotSpace.yRange location %f length %f", CPTDecimalDoubleValue([plotSpace.yRange location]), CPTDecimalDoubleValue([plotSpace.yRange length]));
    
    // Axes 
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalFromInt(1);
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    x.minorTicksPerInterval = 0;
    
//    x.visibleRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(1.0+[self.pointArray count])];
//    NSLog(@"x.visibleRange length %f", CPTDecimalDoubleValue([x.visibleRange length]));
    
    // Define some custom labels for the data elements
    x.labelRotation = M_PI/4;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    NSUInteger labelLocation = 0;
    NSMutableArray *customLabels = [NSMutableArray arrayWithCapacity:[self.labelsArray count]];
    for (NSNumber *tickLocation in self.labelsTickLocationsArray) {
        CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText: [self.labelsArray objectAtIndex:labelLocation++] textStyle:x.labelTextStyle];
        newLabel.tickLocation = [tickLocation decimalValue];
        newLabel.offset = x.labelOffset + x.majorTickLength;
        newLabel.rotation = M_PI/4;
        [customLabels addObject:newLabel];
        [newLabel release];
    }    
    x.axisLabels =  [NSSet setWithArray:customLabels];

    CPTXYAxis *y = axisSet.yAxis;
//    y.majorIntervalLength = CPTDecimalFromInt(unit);
    y.preferredNumberOfMajorTicks = 5;
    y.minorTicksPerInterval = 5;
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:3];
    [numberFormatter setPositiveFormat:@"###0.000"];
    y.labelFormatter = numberFormatter;
    
//    y.visibleRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-1.0+[self.yMin doubleValue]) length:CPTDecimalFromDouble(1.0+[self.yMax doubleValue]-[self.yMin doubleValue])];
//    NSLog(@"y.visibleRange length %f", CPTDecimalDoubleValue([y.visibleRange length]));
    
    y.delegate = self;
    
    [self addPlotForPoints:self.pointArray andGraphHasToBeCleared:NO];
    
    [hostingView release];
    
    return;
}


-(void)addPlotForPoints:(NSMutableArray *)points andGraphHasToBeCleared:(BOOL)hasToBeCleared 
{ 
    if(hasToBeCleared){
        self.dataForPlot = [NSMutableArray array];
    }
    
    // Create a green plot area
    
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth	= 3.f;
    lineStyle.lineColor = [CPTColor greenColor];
    lineStyle.dashPattern = [NSArray arrayWithObjects:[NSNumber numberWithFloat:5.0f], [NSNumber numberWithFloat:5.0f], nil];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    dataSourceLinePlot.identifier = [NSNumber numberWithInt:[self.dataForPlot count]];
    dataSourceLinePlot.dataSource = self;
    dataSourceLinePlot.delegate						   = self;
	dataSourceLinePlot.plotSymbolMarginForHitDetection = 10.0;
    
    // Put an area gradient under the plot above
    
    CPTColor *areaColor	= [CPTColor colorWithComponentRed:0.3 green:1.0 blue:0.3 alpha:0.8];
    
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
    areaGradient.angle = -90.0f;
    
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    dataSourceLinePlot.areaFill = areaGradientFill;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:2];
    
    NSString *yString = [formatter stringFromNumber:self.yMin];
    dataSourceLinePlot.areaBaseValue = CPTDecimalFromString(yString);
    
    // Add plot symbols
    
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor blackColor];
    
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill	= [CPTFill fillWithColor:[CPTColor redColor]];
    plotSymbol.lineStyle = nil;
    plotSymbol.size = CGSizeMake(5.0, 5.0);
    dataSourceLinePlot.plotSymbol = plotSymbol;
    dataSourceLinePlot.opacity = 0.0f;
    
    [self.graph addPlot:dataSourceLinePlot];
    
    // Add text annotations
    
//    for(int i = 0; i < [points count]; i++) {
//        
//        NSDictionary *dict = [points objectAtIndex:i];
//        
//        // Determine point of symbol in plot coordinates
//        
//        NSNumber *x = [dict valueForKey:@"x"];
//        NSNumber *y = [dict valueForKey:@"y"];
//        
//        NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
//        
//        // Add annotation
//        
//        // First make a string for the y value
//        
//        [formatter setMaximumFractionDigits:3];
//        NSString *yString = [formatter stringFromNumber:y];
//        
//        // Setup a style for the annotation
//        
//        CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
//        hitAnnotationTextStyle.color = [CPTColor whiteColor];
//        hitAnnotationTextStyle.fontSize = 12.0f;
//        hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
//        
//        CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle];
//        
//        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.graph.defaultPlotSpace;
//        
//        CPTPlotSpaceAnnotation *symbolTextAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plotSpace anchorPlotPoint:anchorPoint];
//        symbolTextAnnotation.contentLayer = textLayer;
//        
//        // cambio lo scostamento a seconda della derivata in ingresso
//        
//        float dispX = 0.0f;
//        float dispY = 12.0f;
//        
//        if([points count] > 1 && i == 0) {
//            
//            NSDictionary *dict = [points objectAtIndex:i + 1];
//            
//            NSNumber *x2 = [dict valueForKey:@"x"];
//            NSNumber *y2 = [dict valueForKey:@"y"];
//            
//            NSDictionary *dispDict = getDisplacementForExtremePoints(x, y, x2, y2, YES);
//            
//            dispX = [[dispDict objectForKey:@"x"] floatValue];
//            dispY = [[dispDict objectForKey:@"y"] floatValue];
//            
////            NSLog(@"calculated displacement %f %f", dispX, dispY);
//        
//        } else if([points count] > 1 && i > 0 && i + 1 < [points count]) {
//            
//            NSDictionary *dict1 = [points objectAtIndex:i - 1];
//            
//            NSNumber *x1 = [dict1 valueForKey:@"x"];
//            NSNumber *y1 = [dict1 valueForKey:@"y"];
//            
//            NSDictionary *dict2 = [points objectAtIndex:i + 1];
//            
//            NSNumber *x2 = [dict2 valueForKey:@"x"];
//            NSNumber *y2 = [dict2 valueForKey:@"y"];
//            
//            NSDictionary *dispDict = getDisplacementForIntermediatePoints(x1, y1, x, y, x2, y2);
//            
//            dispX = [[dispDict objectForKey:@"x"] floatValue];
//            dispY = [[dispDict objectForKey:@"y"] floatValue];
//            
////            NSLog(@"calculated displacement %f %f", dispX, dispY);
//            
//        } else if([points count] > 1 && i == [points count] - 1) {
//            
//            NSDictionary *dict = [points objectAtIndex:i - 1];
//            
//            NSNumber *x2 = [dict valueForKey:@"x"];
//            NSNumber *y2 = [dict valueForKey:@"y"];
//            
//            NSDictionary *dispDict = getDisplacementForExtremePoints(x2, y2, x, y, NO);
//            
//            dispX = [[dispDict objectForKey:@"x"] floatValue];
//            dispY = [[dispDict objectForKey:@"y"] floatValue];
//            
////            NSLog(@"calculated displacement %f %f", dispX, dispY);
//            
//        } else if([points count] == 1) {
//            ; // TENGO IL DEFAULT
//        } else {
//            ;
//        }
//        
//        symbolTextAnnotation.displacement = CGPointMake(dispX, dispY);
//        
//        [self.graph.plotAreaFrame.plotArea addAnnotation:symbolTextAnnotation];
//        
//        [textLayer release];
//        
//        [symbolTextAnnotation release];
//        
//    }
    
    // Animate in the new plot
    
    CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeInAnimation.duration = 1.0f;
    fadeInAnimation.removedOnCompletion = NO;
    fadeInAnimation.fillMode = kCAFillModeForwards;
    fadeInAnimation.toValue = [NSNumber numberWithFloat:1.0];
    [dataSourceLinePlot addAnimation:fadeInAnimation forKey:@"animateOpacity"];

    [self.dataForPlot addObject:points];
    
    [formatter release];

    [dataSourceLinePlot release];

}

#pragma mark -
#pragma mark CPTScatterPlot delegate method

-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index
{
    if (symbolTextAnnotation && lastSelectedIndex == index) {
        [graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
		symbolTextAnnotation = nil;
        return;
    } else if (symbolTextAnnotation && lastSelectedIndex != index) {
		[graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
		symbolTextAnnotation = nil;
	}
    
    lastSelectedIndex = index;
    
    NSNumber * plotId  = (NSNumber *)plot.identifier;
    NSMutableArray *contentArray = [self.dataForPlot objectAtIndex:[plotId intValue]];
    
	// Setup a style for the annotation
	CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
	hitAnnotationTextStyle.color	= [CPTColor whiteColor];
	hitAnnotationTextStyle.fontSize = 16.0f;
	hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
    
	// Determine point of symbol in plot coordinates
	NSNumber *x			 = [[contentArray objectAtIndex:index] valueForKey:@"x"];
	NSNumber *y			 = [[contentArray objectAtIndex:index] valueForKey:@"y"];
	NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
    
	// Add annotation
	// First make a string for the y value
	NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
	[formatter setMaximumFractionDigits:2];
	NSString *yString = [formatter stringFromNumber:y];
    
	// Now add the annotation to the plot area
	CPTTextLayer *textLayer = [[[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle] autorelease];
	symbolTextAnnotation			  = [[[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint] autorelease];
	symbolTextAnnotation.contentLayer = textLayer;
	symbolTextAnnotation.displacement = CGPointMake(0.0f, 20.0f);
	[graph.plotAreaFrame.plotArea addAnnotation:symbolTextAnnotation];
}


#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSNumber * plotId  = (NSNumber *)plot.identifier;
    NSMutableArray *contentArray = [self.dataForPlot objectAtIndex:[plotId intValue]];
	return [contentArray count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    
    NSNumber * plotId  = (NSNumber *)plot.identifier;
    NSMutableArray *contentArray = [self.dataForPlot objectAtIndex:[plotId intValue]];
    
//    NSLog(@"%i - contentArray: %@",[plotId intValue], contentArray);

    NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
    NSNumber *num = [[contentArray objectAtIndex:index] valueForKey:key];

    return num;

}

#pragma mark -
#pragma mark Axis Delegate Methods

-(BOOL)axis:(CPTAxis *)axis shouldUpdateAxisLabelsAtLocations:(NSSet *)locations
{
	static CPTTextStyle *positiveStyle = nil;
	static CPTTextStyle *negativeStyle = nil;
    
	NSNumberFormatter *formatter = axis.labelFormatter;
	CGFloat labelOffset = axis.labelOffset;
	NSDecimalNumber *zero = [NSDecimalNumber zero];
    
	NSMutableSet *newLabels = [NSMutableSet set];
    
	for (NSDecimalNumber *tickLocation in locations) {
		CPTTextStyle *theLabelTextStyle;
        
		if ([tickLocation isGreaterThanOrEqualTo:zero]) {
			if (!positiveStyle) {
				CPTMutableTextStyle *newStyle = [axis.labelTextStyle mutableCopy];
				newStyle.color = [CPTColor whiteColor];
				positiveStyle = newStyle;
			}
			theLabelTextStyle = positiveStyle;
		}
		else {
			if (!negativeStyle) {
				CPTMutableTextStyle *newStyle = [axis.labelTextStyle mutableCopy];
				newStyle.color = [CPTColor redColor];
				negativeStyle  = newStyle;
			}
			theLabelTextStyle = negativeStyle;
		}
        
		NSString *labelString = [formatter stringForObjectValue:tickLocation];
		CPTTextLayer *newLabelLayer = [[CPTTextLayer alloc] initWithText:labelString style:theLabelTextStyle];
        
		CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithContentLayer:newLabelLayer];
		newLabel.tickLocation = tickLocation.decimalValue;
		newLabel.offset = labelOffset;
        
		[newLabels addObject:newLabel];
        
		[newLabel release];
		[newLabelLayer release];
	}
    
	axis.axisLabels = newLabels;
    
	return NO;
}


- (void)dealloc {
    [self.graph release];
    [self.dataForPlot release];
    [self.labelsArray release];
    [self.labelsTickLocationsArray release];
    [self.pointArray release];
    [self.yMax release];
    [self.yMin release];
    [super dealloc];
}

@end
