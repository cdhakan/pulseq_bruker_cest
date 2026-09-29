/* ***************************************************************
 *
 * Copyright (c) 2024
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
 *   it contains functions necessary for responding to a 'load'
 *	of this method. This function will be automatically
 *	called in response to a method file for this method
 *	having been read.
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


/* ------------------------------------------------------------ 
  backbone 
  The main part of method code. The consitency of all parameters is checked
  chere, relations between them are resolved and, finally, functions setting
  the base level parameters are called.
  --------------------------------------------------------------*/
void backbone( void )
{

/* -----------------------CEST WASABI---------------------------*/
	DB_MSG(("including CEST relations into backbone.c"));
	STB_UpdateRFPulse("CESTpulse00", 1, PVM_DeriveGains, Conventional);
	cest_RFduration_relation();
	cest_delay_relation();
	cest_phase_relation();
	cest_pwrEquiv_relation();
	cest_pulseID_relation();
	cest_freq_relation();
	cest_TotTime_relation();
	cest_pwrIntRat_relation();
	cest_power_relation();/*call this after the other relations were called!*/
/* -----------------------CEST WASABI---------------------------*/
  int dim, ret, nImagesPerRep;
  double minFov[3] = {1e-3, 1e-3, 1e-3},
         minThickness;
  double limExSliceGradient = 100;
  double limExSliceRephaseGradient = 50;

  
  
  DB_MSG(("Entering EPI/backbone.c:backbone"));


  /* Nuclei and  PVM_GradCalConst  are handled by this funtion: */
  STB_UpdateNuclei(Yes);
 
 
  /* do not allow a-aliasing */
  PVM_AntiAlias[1] = 1.0;

  //constrain geometry
  STB_ConstrainSliceGeoForMb(PVM_MbEncNBands);
  
  /* Encoding
   * note: Grappa reference lines are disabled. Grappa coeeficients will be set
   * in a special adjustment. */
  STB_UpdateEncodingForEpi(
    &NSegments,        /* number of segments */
    Yes,               /* ppi in 2nd dim allowed */
    Yes,               /* ppi ref lines in 2nd dim allowed */
    Yes,               /* partial ft in 2nd dim allowed */ 
    3);

  dim = PTB_GetSpatDim();
  
  /* handle RF pulse */   
  
  STB_UpdateRFPulse("ExcPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
  STB_UpdateRFPulse("RefPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");

  if (TempGridding)
  {
    double fac=ExcPul.Rpfac/100.0;
    if (fac < 0.01)
      fac=1.0;
    else
      fac=round(1.0/fac);

    ExcPul.Length=ceil(ExcPul.Length/fac*1000.0)/1000.0*fac; //Total pulse on grid and MOST(!) length*Rpfac on grid
    ExcPul.Bandwidth= MRT_RFPulsePulseLengthToBandwidth(ExcPul.Bwfac, 100.0,ExcPul.Length);
    STB_UpdateRFPulse("ExcPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
    RefPul.Length=ceil(RefPul.Length*1000.0/2.0)/1000.0*2.0; //half pulse on grid
    RefPul.Bandwidth= MRT_RFPulsePulseLengthToBandwidth(RefPul.Bwfac, 100.0,RefPul.Length);
    STB_UpdateRFPulse("RefPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");

    RephaseTime=ceil(RephaseTime*1000.0)/1000.0;
    PackDel=ceil(PackDel*1000.0)/1000.0;
  }
  
  if(PVM_DeriveGains==Yes)
  {
    ParxRelsParHideInEditor({"ExcPulseAmpl"});
  }
  else
  {
    ParxRelsParShowInEditor({"ExcPulseAmpl"});
  }
  
  if (PVM_SignalType == SignalType_Fid)
  {
    ParxRelsParHideInEditor({"RefPul","RefPulseEnum","RefPulseAmpl"});
  }
  else
  {
    ParxRelsParShowInEditor({"RefPul","RefPulseEnum"});
    if (PVM_DeriveGains == Yes)
    {
      ParxRelsParHideInEditor({"RefPulseAmpl"});
    }
    else
    {
      ParxRelsParShowInEditor({"RefPulseAmpl"});
    }
  }
    
  /*** Update Geometry **/
  
  LocalGeometryMinimaRels(limExSliceGradient, limExSliceRephaseGradient, &minThickness);

  /* do not allow isotropic geometry */
  PVM_IsotropicFovRes = Isot_None;

  // only one package
  int maxPackages = 1;
  int maxPerPackage = dim>2? 1:0;

  STB_UpdateImageGeometry(dim, 
                          PVM_Matrix,
                          minFov,
                          0, // total slices (no restr)
                          maxPackages,
                          maxPerPackage,
                          minThickness,
                          1.0); // sliceFovRatio in 3D

  STB_UpdateMultiBandGeoPars("PVM_SliceGeoObj", 
        PVM_ObjOrderScheme,
        PVM_MbEncNBands);
  
  /** Update EPI parameter group */

  PVM_NRepetitions = MAX_OF(1,PVM_NRepetitions);
  PVM_NEchoImages = 1;
  nImagesPerRep = PVM_NEchoImages * GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );

  ret = STB_EpiUpdate(No,
		      dim, 
		      PVM_EncMatrix, 
		      PVM_AntiAlias,
		      PVM_Fov, 
		      minFov, 
		      &PVM_EffSWh, 
		      PVM_GradCalConst, 
		      nImagesPerRep,
		      NSegments,
		      PVM_EncCentralStep1,
		      PVM_EncPpi,
                      PVM_EncNReceivers,
                      TempGridding,
                      PVM_MbEncNBands,
                      PVM_MbEncBlipFactor,
                      PVM_EncGenCaipirinha);

  if(ret <0)
    DB_MSG(("--!!!!!!!!!!!!!!! Illegal arguments for STB_UpdateEPI: EPI Module not ready !"));
 
  /* Constrain MB geometry, min slice distance (minFov[2]) is known */
  STB_ConstrainSliceGeoForMb(PVM_MbEncNBands,minFov[2]);
              
  /* Update geometry again (minFov is known) */ 
  
  STB_UpdateImageGeometry(dim, 
                          PVM_Matrix,
                          minFov,
                          0, // total slices (no restr)
                          maxPackages,
                          maxPerPackage,
                          minThickness,
                          1.0); // sliceFovRatio in 3D
  STB_UpdateEpiTrajGeometry(PVM_SpatResol[0], "PVM_SliceGeo");

  STB_UpdateMultiBandGeoPars("PVM_SliceGeoObj", 
        PVM_ObjOrderScheme,
        PVM_MbEncNBands);
  
  //Update RF Pulses, mb-parameters might have changed
  STB_UpdateRFPulse("ExcPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
  STB_UpdateRFPulse("RefPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
  STB_UpdateAtsReferencePosition("PVM_SliceGeoObj");

  /*** end Update Geometry **/

  LocalGradientStrengthRels();  
  LocalFrequencyOffsetRels();

  if (ParxRelsParHasValue("PVM_NAverages") == 0)
     PVM_NAverages = 1;

  /* update slice spoiler */
  double mindurSlice = MAX_OF(2.0, 2.0*CFG_GradientRiseTime());
  double spoilerThick = dim>2 ? PVM_SpatResol[2]*PVM_EncZf[2] : PVM_SliceThick;
  MRT_UpdateSpoiler("SliceSpoiler",5.0,limExSliceGradient,mindurSlice,PVM_GradCalConst,spoilerThick);

  if (TempGridding)
    GridGrad(&SliceSpoiler.dur, &SliceSpoiler.ampl, mindurSlice, 50, 0, limExSliceGradient);



  /* handling of modules */
  STB_UpdateDriftCompModule(spoilerThick, PVM_DeriveGains);
  STB_UpdateFatSupModule(PVM_Nucleus1, PVM_DeriveGains, spoilerThick);
  STB_UpdateSatTransModule(PVM_DeriveGains);
  STB_UpdateFovSatModule(PVM_Nucleus1, PVM_DeriveGains);
  STB_UpdateTriggerModule();
  STB_UpdateTriggerOutModule();
  STB_UpdateTaggingModule(dim,PVM_Fov,PVM_Matrix,PVM_SpatResol[0]*PVM_EncZf[0],PVM_DeriveGains); 

  rfcSpoilerUpdate();

  echoTimeRels();

  if (TempGridding)
  {
     EchoTime=ceil(EchoTime*1000.0)/1000.0;
  }

  repetitionTimeRels();

  PTB_ClearAdjustments();

  PTB_AppendOrderAdjustment(per_scan, per_scan, RG_ADJNAME);

  PTB_AppendAdjustment("EpiTraj",
                       "Adjust Traj.",
                       "Adjust EPI Trajectory",
                       on_demand);
  
  if (ReversePE == PreScan)
  {
    if(PVM_EncPpiRefScan)
    {
      PTB_AppendAdjustment("EpiRevGrappa",
                           "Adjust RevPE GRAPPA Coeff.",
                           "Adjustment of Reversed PE GRAPPA Coefficients",
                           per_scan);
      if(PVM_MbEncAccelFactor > 1){
          PTB_AppendAdjustment("MbRgGhost",
                          "Receiver Gain MB", 
                          "Re-Adjustment of the Receiver Gain for Multi-Band",
                          per_scan);
      }    
    }      
    PTB_AppendAdjustment("ReversedPE",
                         "Reversed PE",
                         "Adjust Sampling with Reversed PE for distortion correction",
                         per_scan);  
    if (PVM_EncPpiRefScan && PVM_MbEncAccelFactor > 1)
        PTB_AppendConfiguredAdjustment(per_scan,RG_ADJNAME);
  }
  
  if(PVM_EncPpiRefScan)
  {
    PTB_AppendAdjustment("EpiGrappa",
                         "Adjust GRAPPA Coeff.",
                         "Adjustment of GRAPPA Coefficients",
                         per_scan);
    if(PVM_MbEncAccelFactor > 1){
        PTB_AppendAdjustment("MbRgGhost",
                        "Receiver Gain MB", 
                        "Re-Adjustment of the Receiver Gain for Multi-Band",
                        per_scan);
    }
  }

  STB_UpdateDummyScans(PVM_RepetitionTime);

  /* Set correct DriftCompUpdateTime after TR-upate */
  STB_UpdateDriftComp(PVM_RepetitionTime);
  
  /* update mapshim parameter class */
  STB_UpdateMapShim(PVM_Nucleus1,"PVM_SliceGeoObj");

  /* set baselevel acquisition parameter */
  SetBaseLevelParam();
  
  /* set baselevel reconstruction parameter */
  SetRecoParam(PVM_EncPpi[1]);
PVM_ScanTime += CEST_TotTime;


  /* adapt size of trajectory arrays if necessary and set 
     PVM_EpiTrajAdj to No if a trajectory relevant parameter has changed */

  STB_EpiCheckTrajectory(PVM_Fov[0],PVM_EffSWh,PVM_SPackArrGradOrient[0][0]);
 
  DB_MSG(("Exiting EPI/backbone.c:backbone"));
}


void rfcSpoilerUpdate(void)
{
  RfcSpoilerStrength = 2*ExSliceGradient;
  RfcSpoilerStrength = MIN_OF(RfcSpoilerStrength,80);
  RfcSpoilerStrength = MAX_OF(RfcSpoilerStrength,30);

  RfcSpoilerDuration = MAX_OF(RefPul.Length, 2*CFG_GradientRiseTime());
}

/****************************************************************/
/*	         L O C A L   F U N C T I O N S			*/
/****************************************************************/


void echoTimeRels( void )
{
  DB_MSG(("Entering EPI/backbone.c:echoTimeRels()"));

  double igwt = CFG_InterGradientWaitTime();
  double riseT = CFG_GradientRiseTime();

  if(PVM_SignalType == SignalType_Fid)
  {
    PVM_MinEchoTime =      /* min gradient echo time */
      ExcPul.Length * ExcPul.Rpfac/100 +
      riseT             +
      igwt              +
      RephaseTime       +
      igwt              +
      PVM_EpiEchoDelay;
    MinTE_right  = MinTE_left = 0.0; /* not used */
  }
  else
  {
    MinTE_left =  /* min half spinecho-time given by left hand side of pi */
    ExcPul.Length * ExcPul.Rpfac/100  +
    riseT             +
    igwt              + 
    RephaseTime       +
    igwt              +
    RfcSpoilerDuration + 
    RefPul.Length/2.0;

    MinTE_right = /* min half spinecho-time given by right hand side of pi */
    RefPul.Length/2.0  +
    RfcSpoilerDuration +
    igwt               +
    PVM_EpiEchoDelay;

    PVM_MinEchoTime = 2 * MAX_OF(MinTE_left, MinTE_right);
  }

  EchoTime = EchoTime < PVM_MinEchoTime ?
    PVM_MinEchoTime : EchoTime;

  if (TempGridding)
  {
    if(PVM_SignalType == SignalType_Fid)

      EchoTime=ceil(EchoTime*1000.0)/1000.0;
    else
      EchoTime=ceil(EchoTime*1000.0/2.0)/1000.0*2.0;
  }

  /* Set Echo Parameters for Scan Editor   */

  /* echo spacing: */
  PVM_EchoTime = 1e3*PVM_Matrix[0]/PVM_EffSWh/PVM_AntiAlias[0];
  PVM_EchoPosition = 50.0;
 
  DB_MSG(("Exiting EPI/backbone.c:echoTimeRels"));
}

void repetitionTimeRels( void )
{
  int nSlices,dim;
  double TotalTime,trigger, trigger_v, trigOutSlice, trigOutVol;

  DB_MSG(("--> minRepetitionTimeRels"));

  trigger = STB_UpdateTriggerModule();
  if(PVM_TriggerMode == per_PhaseStep) /* per volume */
  {
    trigger_v=trigger;
    trigger=0.0; 
  }
  else trigger_v=0.0;

  TotalTime = 0.0;
  nSlices = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices )/PVM_MbEncNBands;

  if(PVM_TriggerOutOnOff == On)
  {
    switch(PVM_TriggerOutMode)
    {
    case PER_SLICE:   
      trigOutSlice = PVM_TriggerOutModuleTime;
      trigOutVol = 0.0;
      break;

    case PER_VOLUME: 
      trigOutSlice = 0.0;
      trigOutVol = PVM_TriggerOutModuleTime;
      break;

    case AT_START:
    default:
      trigOutSlice = 0.0;
      trigOutVol = 0.0;
      
    }
  }
  else
    trigOutSlice = trigOutVol = 0.0;

  dim = PTB_GetSpatDim();
  
  if(dim>2) /* disable inter-volume delay in 3d */
  {
    PackDel=0;
    ParxRelsParMakeNonEditable({"PackDel"});
  }
  else
  {
    ParxRelsParMakeEditable({"PackDel"});
  }

  double dynshim_event=0;
  if(PVM_DynamicShimEnable==Yes)
    dynshim_event = PVM_DynamicShimEventDuration;
  
  PVM_MinRepetitionTime =
    nSlices * (
               0.03 +                      //UpdateDynPars
               dynshim_event +
               0.01 + 
               PVM_FatSupModuleTime +
               PVM_FovSatModuleTime +
               PVM_SatTransModuleTime +
               trigger +
               trigOutSlice +
               SliceSpoiler.dur +
	             CFG_GradientRiseTime() +
               ExcPul.Length/2 +
               EchoTime +
               PVM_EpiModuleTime - PVM_EpiEchoDelay
    ) + 
    PVM_DriftCompModuleTime +
    PVM_TaggingModuleTime +
    trigOutVol +
    trigger_v +
    PackDel;

  PVM_RepetitionTime = ( PVM_RepetitionTime < PVM_MinRepetitionTime ? 
			 PVM_MinRepetitionTime : PVM_RepetitionTime );

  if (TempGridding)
    PVM_RepetitionTime=ceil(((PVM_RepetitionTime - PVM_MinRepetitionTime)/nSlices)*1000.0)/1000.0*nSlices+PVM_MinRepetitionTime;

  
  /** Calculate Total Scan Time and Set for Scan Editor **/ 

  if( dim >1 )
    TotalTime = PVM_RepetitionTime      *
                PVM_EpiNShots           *
                PVM_NAverages           *
                PVM_SatTransRepetitions *
                PVM_NRepetitions;

  if( dim >2 )
    TotalTime *= PVM_EncMatrix[2];

  /* time for one repetition */
  OneRepTime = TotalTime/(PVM_NRepetitions*1000.0);

  PVM_ScanTime = TotalTime;
  UT_ScanTimeStr(PVM_ScanTimeStr,TotalTime);
 

  ParxRelsParShowInEditor({"PVM_ScanTimeStr"});
  ParxRelsParMakeNonEditable({"PVM_ScanTimeStr"});

  DB_MSG(("<-- repetitionTimeRels"));
}

void LocalGeometryMinimaRels(double limExSliceGradient, double limExSliceRephaseGradient, double *min_thickness)
{
  /*
    This function calculates the minima for the minimum  slice thickness.
    It is always assumed that all slices have the same thickness
    (WE DO NOT set min_fov[0 and 1] here, this will be done by the epi module) 
 */

  double sliceRampInteg; /* normalised integral falling slice gradient ramp */
  double sliceRephInteg; /* normalised integral slice rephase gradient      */
    
  /* min slice thickness: */
  /*  Calculate the normalised integral of the descending gradient ramp after
      the RF pulse */
  sliceRampInteg = 0.5 *  CFG_GradientRiseTime();
  /* Calculate the normalised integral of the slice selection rephasing
     gradient */
  sliceRephInteg = RephaseTime - CFG_GradientRiseTime();
  
  /*
	Calculate the ratio of the strength of the slice selection gradient to
	the strength of the slice selection rephase gradient

  */
  SliceGradRatio = MRT_SliceGradRatio( ExcPul.Length,
                                       ExcPul.Rpfac,
                                       0.0,
                                       sliceRampInteg,
                                       sliceRephInteg );
  /*
    Calculate the minimum slice thickness
  */
      
  *min_thickness = MRT_MinSliceThickness( ExcPul.Bandwidth,
					  SliceGradRatio,
					  limExSliceGradient,
					  limExSliceRephaseGradient,
					  PVM_GradCalConst );
     
    
} /* end of localGeometryMinima() */



void LocalGradientStrengthRels( void )
{
  /*
    This function calculates all the gradient strengths 
  */

  switch( PTB_GetSpatDim() )
    {
    case 3: /* PHASE ENCODING GRADIENT - 3nd DIM */
     
     /* falls through */
    case 1:
      ReadGradient = (PVM_EpiReadEvenGrad+PVM_EpiReadOddGrad)/2.0; /* used in LocFreqOff */
      [[fallthrough]];
     /* falls through */
    default: /* SLICE SELECTION GRADIENT */
      ExSliceGradient = MRT_SliceGrad( ExcPul.Bandwidth,
				       PVM_SliceThick,
				       PVM_GradCalConst );
      ExSliceRephaseGradient = MRT_SliceRephaseGrad( SliceGradRatio,
							 ExSliceGradient );
      break;
    }
}

void LocalFrequencyOffsetRels( void )
{
  int spatDim;
  int i,nslices;

  spatDim = PTB_GetSpatDim();

  nslices = GTB_NumberOfSlices(PVM_NSPacks,PVM_SPackArrNSlices);

  if(PVM_MbEncNBands > 1){
    nslices /= PVM_MbEncNBands;
    /* set ReadOffsetHz to zero. In EPI the fov offset is made by reco, not by detection freq. offsets */
    MRT_FrequencyOffsetList(nslices,
                            PVM_MbEffReadOffset,
                            ReadGradient,
                            0.0, /* instead PVM_GradCalConst; this sets offHz to zero */
                            PVM_MbReadOffsetHz );

    MRT_FrequencyOffsetList(nslices,
                            PVM_MbEffSliceOffset,
                            ExSliceGradient,
                            PVM_GradCalConst,
                            PVM_MbSliceOffsetHz );
  }
  
    /* set ReadOffsetHz to zero. In EPI the fov offset is made by reco, not by detection freq. offsets */
    MRT_FrequencyOffsetList(nslices,
			  PVM_EffReadOffset,
			  ReadGradient,
			  0.0, /* instead PVM_GradCalConst; this sets offHz to zero */
			  PVM_ReadOffsetHz );

  MRT_FrequencyOffsetList(nslices,
			  PVM_EffSliceOffset,
			  ExSliceGradient,
			  PVM_GradCalConst,
			  PVM_SliceOffsetHz );

  if(spatDim == 3)
  {
    for(i=0;i<nslices;i++)
      PVM_EffPhase2Offset[i] = -PVM_EffSliceOffset[i];
  }

}



//rounds dur and rescales amp, checking limits
bool GridGrad(double* durPt, double* ampPt, double minDur, double maxDur, double minAmp, double maxAmp)
{
  //input in ms

  double dur=*durPt*1000.0;
  double amp=*ampPt;
  minDur*=1000.0;
  maxDur*=1000.0;

  double origDur=dur;
  double origAmp=amp;
  double fac=1.0;
  bool failed=false;

  DB_MSG(("origDur %f", origDur));

  //set dur
  dur=ceil(origDur);
  DB_MSG(("ceil %f", dur));


  if (dur > maxDur)
    dur=floor(origDur);
   DB_MSG(("floor? %f", dur));


  //set amp
  fac=dur/origDur;
  amp=origAmp/fac;

  DB_MSG(("origAmp %f amp %f", origAmp, amp));


  //check amp
  if (amp > maxAmp)
    dur=ceil(origDur);
  if (amp < minAmp)
    dur=floor(origDur);
  
  DB_MSG(("dur %f", dur));


  //re-adjust amp
  fac=dur/origDur;
  amp=origAmp/fac;

  DB_MSG(("amp %f", amp));

  
  //final check
  if (dur < minDur || dur > maxDur || amp < minAmp || amp > maxAmp)
  {
    failed=true;
    dur=origDur;
    amp=origAmp;
  }

  *durPt=dur/1000.0;
  *ampPt=amp;

  return failed;
}



/****************************************************************/
/*		E N D   O F   F I L E				*/
/****************************************************************/
