/****************************************************************
 *
 * Copyright (c) 1999-2022
 * Bruker BioSpin GmbH & Co. KG
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 ****************************************************************/

/****************************************************************/
/*	PARAMETER CLASSES				       	*/
/****************************************************************/


/*--------------------------------------------------------------*
 * Definition of the PV class...
 *--------------------------------------------------------------*/

pargroup
{
  PVM_EffSWh; 
  RephaseTime;
  PVM_MinFov;
  PVM_MinSliceThick;
  SliceSpoiler;
  ReversePE; 
  ReversePEAdjRunning;
}
attributes
{
  display_name "Sequence Details";
} Sequence_Details;

pargroup
{
  ExcPulseEnum;
  ExcPul;
  ExcPulseAmpl;
  ExcPulseShape;
  RefPulseEnum;
  RefPul;
  RefPulseAmpl;
  RefPulseShape;
} 
attributes
{
  display_name "RF Pulses";
} RF_Pulses;

pargroup
{
  DummyScans_Parameters;

  PVM_TriggerModule;
  Trigger_Parameters;

  PVM_TaggingOnOff;
  Tagging_Parameters;

  PVM_FatSupOnOff;
  Fat_Sup_Parameters;

  PVM_SatTransOnOff;
  Sat_Transfer_Parameters;

  PVM_FovSatOnOff;
  Fov_Sat_Parameters;

  PVM_TriggerOutOnOff;
  TriggerOut_Parameters;

  DriftComp_Parameters;
} Preparation;

pargroup
{
	CEST_freqList;
	CEST_pwrLIST;
	CEST_RFduration;
	CEST_DelayList;
	CEST_PhaseList;
	CEST_pulseID;
	CEST_pwrEquiv;
	CEST_pwrIntRat;
	CEST_TotTime;
}
attributes
{
	display_name "CEST";
} CEST_Parameters;

extend pargroup
{
  PVM_EffSWh;
  EchoTime;
  PVM_MinEchoTime;
  PVM_EchoTime;
  NSegments;
  PVM_RepetitionTime;
  PackDel;
  PVM_NEchoImages;
  PVM_NAverages;
  PVM_NRepetitions;
  PVM_ScanTimeStr;
  PVM_ScanTime;
  PVM_SignalType;
  PVM_DeriveGains;
  Encoding;
  EPI_Parameters;
  RF_Pulses;
  Nuclei;
  Sequence_Details;
  ImageGeometry;
  Preparation;
  MapShim;
  TempGridding;
  GopAdj;
	CEST_Parameters;
} MethodClass;

// parameters for reconstruction 
extend pargroup
{
  ParentDset; 
  NeuralNetworkGroup;  
}
attributes
{
  display_name "Reconstruction Options";
}MethodRecoGroup;

// parameters that should be tested after any editing
conflicts
{
  EchoTime;
  PVM_RepetitionTime;
  PVM_Fov;
  PVM_SliceThick;
  NSegments;
  ExcPul.Flipangle;
  RefPul.Flipangle;  
};

/****************************************************************/
/*	E N D   O F   F I L E					*/
/****************************************************************/



