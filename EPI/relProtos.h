/****************************************************************
 *
 * Copyright (c) 2013 - 2020
 * Bruker BioSpin GmbH & Co. KG
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 ****************************************************************/

#ifndef METHRELS_H
#define METHRELS_H

/* gen/src/prg/methods/EPI/initMeth.c */
void initMeth(void);
/* gen/src/prg/methods/EPI/loadMeth.c */
void loadMeth(const char *);
/* gen/src/prg/methods/EPI/parsRelations.c */
void ExcPulseEnumRelation(void);
void ExcPulRelation(void);
void ExcPulRange(void);
void ExcPulseAmplRel(void);
void RefPulseEnumRelation(void);
void RefPulRelation(void);
void RefPulRange(void);
void RefPulseAmplRel(void);
void HandleRFPulseAmplitudes(void);
void PackDelRange(void);
void PackDelRelation(void);
void RephaseTimeRels(void);
void RephaseTimeRange(void);
void Local_NAveragesRange(void);
void Local_NAveragesHandler(void);
void LocalSWhRange(void);
void LocalSWhRels(void);
void NSegmentsRels(void);
void NSegmentsRange(void);
void SliceSpoilerRel(void);
/* gen/src/prg/methods/EPI/BaseLevelRelations.c */
void SetBaseLevelParam(void);
void SetBasicParameters(void);
void SetFrequencyParameters(void);
void SetGradientParameters(void);
void SetInfoParameters(void);
void SetPpgParameters(void);
void SetAcquisitionParameters(void);
void SetRevPEAdj(void);
/* gen/src/prg/methods/EPI/RecoRelations.c */
void SetRecoParam(int);
void RecoDerive(void);
/* gen/src/prg/methods/EPI/adjust.c */
void HandleAdjustmentRequests(void);
void HandleAdjustmentResults(void);
void HandleGopAdjResults(void);
void setRGGhostAdj(YesNo);
void setSpinEcho(void);
void setTrajAdj(void);
/* gen/src/prg/methods/EPI/backbone.c */
void backbone(void);
void rfcSpoilerUpdate(void);
void echoTimeRels(void);
void repetitionTimeRels(void);
void LocalGeometryMinimaRels(double, double, double *);
void LocalGradientStrengthRels(void);
void LocalFrequencyOffsetRels(void);
bool GridGrad(double *, double *, double, double, double, double);
/* gen/src/prg/methods/EPI/deriveVisu.c */
void deriveVisu(void);


/* -----------------------CEST WASABI---------------------------*/
void cest_delay_relation(void);
void cest_phase_relation(void);
void cest_freq_relation(void);
void cest_power_relation(void);
void cest_pulseID_relation(void);
void cest_pwrEquiv_relation(void);
void cest_pwrIntRat_relation(void);
void cest_RFduration_relation(void);
void cest_TotTime_relation(void);
void cestpulse00Relation(void);
/* -----------------------CEST WASABI---------------------------*/

#endif

/****************************************************************/
/*      E N D   O F   F I L E                                   */
/****************************************************************/

