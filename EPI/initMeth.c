/* ***************************************************************
 *
 * Copyright (c) 2022
 * Bruker BioSpin GmbH & Co. KG
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 * ***************************************************************/

#define DEBUG	 0

/*:=INFO=:*******************************************************
 *
 * Description :
 *   it contains functions necessary for initialisation of the
 *	onepulse method.
 *
 *::=info=:******************************************************/

/****************************************************************/
/****************************************************************/
/*		I N T E R F A C E   S E C T I O N		*/
/****************************************************************/
/****************************************************************/

/****************************************************************/
/*		I N C L U D E   F I L E S			*/
/****************************************************************/

#include "method.h"

/****************************************************************/
/*	I M P L E M E N T A T I O N   S E C T I O N		*/
/****************************************************************/


/****************************************************************/
/*		G L O B A L   F U N C T I O N S			*/
/****************************************************************/


/*:=MPB=:=======================================================*
 *
 * Global Function: initMeth
 *
 * Description: This procedure is implicitly called when this
 *	method is selected.
 *
 * Error History: 
 *
 * Interface:							*/

void initMeth()
/*:=MPE=:=======================================================*/
{

/* -----------------------CEST WASABI---------------------------*/
	STB_InitRFPulse("CESTpulse00",    // name of pulse structure
			0,			// name of pulse list parameter
			0,			// name of pulse amplitude parameter
			0,			// name of pulse shape (for calc. pulses)
			0,			// used for excitation
			"cest_pulse00.exc",	 // default shape 
			3000.0,			// default bandwidth
			30.0);			// default pulse angle
/* -----------------------CEST WASABI---------------------------*/

  int dimRange[2] = { 2,3 };
  int lowMat[3] = { 16, 16, 8 };
  int upMat[3]  = { 512, 512, 256 };
  int defaultMat[3] = {96, 64, 32};

  DB_MSG(( "Entering epi2:initMeth()" ));

  
  /*  Initialize NA ( see code in parsRelations ) */
  Local_NAveragesRange();

  RephaseTimeRange();

  /* segments */
  NSegmentsRange();

  /* Encoding */
  STB_InitEncoding( 2, dimRange, lowMat, upMat, defaultMat);  

  /*Initialisation of repetitions time*/
  if(ParxRelsParHasValue("PVM_RepetitionTime") == No)
      PVM_RepetitionTime = 1000;

  /*Initialisation of automatic derive RF gains*/
  if(ParxRelsParHasValue("PVM_DeriveGains") == No)
      PVM_DeriveGains = Yes;

  /* Initialisation of signal type */
  if(ParxRelsParHasValue("PVM_SignalType") == No)
      PVM_SignalType = SignalType_Echo;


  /* Initialisation of rf pulse parameters */
  
  STB_InitRFPulse("ExcPul",        // name of pulse structure
                  "ExcPulseEnum",  // name of pulse list parameter
                  "ExcPulseAmpl",  // name of pulse amplitude parameter
                  "ExcPulseShape", // name of pulse shape (for calc. pulses)
                  0,               // used for excitation
                  "Calculated", // default shape
                  2000.0,          // default bandwidth
                  90.0);           // default pulse angle
  ExcPulRange();

  STB_InitRFPulse("RefPul",        // name of pulse structure
                  "RefPulseEnum",  // name of pulse list parameter
                  "RefPulseAmpl",  // name of pulse amplitude parameter
                  "RefPulseShape", // name of pulse shape (for calc. pulses)
                  1,               // used for excitation
                  "Calculated", // default shape
                  2000.0,          // default bandwidth
                  180.0);          // default pulse angle
  RefPulRange();

  /* Initialisation of nucleus and frequency */  
  STB_InitNuclei(1);


  /* Initialisation of the delay between the slices packages */  
  PackDelRange();
 
  /* Initialisation of spoilers */
  MRT_InitSpoiler("SliceSpoiler");
  
  /* Initialisation of geometry parameters */ 
  STB_InitImageGeometry();
    
  /* initializtion of bandwidth */
  LocalSWhRange();
 
  /* Initialisation of modules */
  STB_InitEpi(UserSlope);
  STB_InitFatSupModule();
  STB_InitSatTransModule();
  STB_InitFovSatModule();
  STB_InitTriggerModule();
  STB_InitTriggerOutModule();
  STB_InitTaggingModule();
  STB_InitDummyScans(1000.0);
  STB_InitDriftComp(On);

  /* initialize mapshim parameter class */
  STB_InitMapShim(Yes);
  
  /* Initialization of trajectory geometry */
  STB_InitEpiTrajGeometry("PVM_SliceGeoObj", "PVM_SliceGeo");  
  
  /* Visibility of Scan Editor parameters */
  ParxRelsParShowInEditor({"PVM_EchoTime","PVM_NEchoImages"});
  ParxRelsParShowInFile({"PVM_EchoTime","PVM_NEchoImages"});
  ParxRelsParMakeNonEditable({"PVM_EchoTime","PVM_MinEchoTime"});
  ParxRelsParMakeNonEditable({"PVM_NEchoImages","PVM_EchoPosition"});


 if(ParxRelsParHasValue("TempGridding") == No)
      TempGridding = No;

  if(!ParxRelsParHasValue("GopAdj"))
    GopAdj = Yes;

  STB_InitAtsReferencePosition();
   
  if(!ParxRelsParHasValue("ReversePE"))
      ReversePE = NoRevPhase;
  if(!ParxRelsParHasValue("ReversePEAdjRunning"))
      ReversePEAdjRunning = No;
  
  
  /* Once all parameters have initial values, the backbone is called
     to assure they are consistent */
  backbone();
 

  DB_MSG(( "Exiting epi2:initMeth()" ));

}



/****************************************************************/
/*		E N D   O F   F I L E				*/
/****************************************************************/









