/****************************************************************
 *
 * $Source$
 *
 * Copyright (c) 1999-2003
 * Bruker BioSpin GmbH & Co. KG
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 * $Id$
 *
 ****************************************************************/



/****************************************************************/
/* INCLUDE FILES						*/
/****************************************************************/


double parameter ExSliceGradient;
double parameter ExSliceRephaseGradient;
double parameter RfcSpoilerStrength;
double parameter RfcSpoilerDuration;
double parameter OneRepTime;

double parameter SliceGradRatio;
double parameter ReadGradient;
double parameter MinTE_left;
double parameter MinTE_right;

double parameter 
{
  display_name "Rephasing/encoding time";
  relations RephaseTimeRels;
  units "ms";
  format "%.2f";
} RephaseTime;


int parameter 
{
  display_name "Segments";
  short_description "Number of Segments.";
  relations NSegmentsRels;
} NSegments;

double parameter
{
  display_name "Echo Time";
  units "ms";
  format "%.3f";
  relations backbone;
} EchoTime;

double parameter
{
  display_name "Inter-Volume Delay";
  short_description "Break after every volume acquisition.";
  format "%.2f";
  units "ms";
  relations PackDelRelation;
} PackDel;

PVM_SPOILER_TYPE parameter 
{
  display_name "Slice Spoiler";
  relations SliceSpoilerRel;
}SliceSpoiler;

PV_PULSE_LIST parameter
{
  display_name "Excitation Pulse Shape";
  relations    ExcPulseEnumRelation;
}ExcPulseEnum;

PV_PULSE_LIST parameter
{
  display_name "Refocusing Pulse Shape";
  relations    RefPulseEnumRelation;
}RefPulseEnum;

PVM_RF_PULSE parameter
{
  display_name "Excitation Pulse";
  relations    ExcPulRelation;
}ExcPul;

PVM_RF_PULSE parameter
{
  display_name "Refocusing Pulse";
  relations    RefPulRelation;
}RefPul;

PVM_RF_PULSE_AMP_TYPE parameter
{
  display_name "Excitation Pulse Amplitude";
  relations ExcPulseAmplRel;
}ExcPulseAmpl;

PVM_RF_PULSE_AMP_TYPE parameter
{
  display_name "Refocusing Pulse Amplitude";
  relations RefPulseAmplRel;
}RefPulseAmpl;

double parameter
{
  editable false;
}ExcPulseShape[];

double parameter
{
  editable false;
}RefPulseShape[];

YesNo parameter
{
  short_description "Calculates all delays on a 1us grid.";
  display_name "1us Gridding";
  relations backbone;
}TempGridding;

ImageSeriesReference parameter ParentDset;
YesNo parameter GopAdj;

YesNo parameter ReversePEAdjRunning;

REV_PHASE_MODE parameter 
{    
  display_name "Reverse Phase Encoding";
  short_description "No: Standard PE; Whole Exp: Whole Exp. acquried with reversed PE; Pre-Scan: One additional set images acquried with reversed PE.";    
  relations backbone;
}ReversePE;

enum_attributes REV_PHASE_MODE
{
  display_name NoRevPhase "No";
  display_name WholeExp   "Whole Exp";
  display_name PreScan    "Pre-Scan";
};

/* -----------------------CEST WASABI---------------------------*/
PVM_RF_PULSE parameter
{
	display_name "CEST_pulse00";
	relations    cestpulse00Relation;
	editable false;
}CESTpulse00;

double parameter
{
	display_name "CEST saturation power";
	relations cest_power_relation;
	units "W";
	format "%.6f";
}CEST_pwrLIST[];
double parameter
{
	display_name "CEST interpulse delay";
	relations cest_delay_relation;
	units "s";
	format "%.6f";
}CEST_DelayList[];
double parameter
{
	display_name "CEST RF duration";
	relations cest_RFduration_relation;
	units "us";
	format "%.6f";
}CEST_RFduration[];
double parameter
{
	display_name "CEST phase list";
	relations cest_phase_relation;
	format "%.6f";
}CEST_PhaseList[];
double parameter
{
	display_name "CEST offset list";
	relations cest_freq_relation;
	units "Hz";
	format "%.6f";
}CEST_freqList[];
double parameter
{
	display_name "CEST power equivalents";
	relations cest_pwrEquiv_relation;
	format "%.6f";
}CEST_pwrEquiv[];
double parameter
{
	display_name "CEST pulse IDs";
	relations cest_pulseID_relation;
	format "%.0f";
}CEST_pulseID[];
double parameter
{
	display_name "total CEST time";
	relations cest_TotTime_relation;
	format "%.6f";
	units "ms";
}CEST_TotTime;
double parameter
{
	display_name "CEST FA equivalents";
	relations cest_pwrIntRat_relation;
	format "%.6f";
	editable false;
}CEST_pwrIntRat[];
/* -----------------------CEST WASABI---------------------------*/
/****************************************************************/
/*	E N D   O F   F I L E					*/
/****************************************************************/

