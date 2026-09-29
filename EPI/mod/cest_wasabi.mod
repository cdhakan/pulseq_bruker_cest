;****************************************************************
; AUTHOR - CHETAN B DHAKAN ; Email - cdhakan@mgh.harvard.edu 
; cest_wasabi.mod : WASABI/CEST presaturation module
;   subr cest_wasabiInit()       ; once - before the NR loop
;   subr cest_wasabi()           ; in the NR loop - presat)
;   subr cest_wasabiInc()        ; in the NR loop - advance to next offset
;****************************************************************

define list<frequency> fCEST     = {$CEST_freqList}
define list<phase>     pCEST     = {$CEST_PhaseList}
define list<delay>     dCEST     = {$CEST_DelayList}
define list<pulse>     rfCEST    = {$CEST_RFduration}
define list<power>     FArfCEST  = {$CEST_pwrLIST}

subroutine cest_wasabiInit()
{
	0u fCEST.res
	0u pCEST.res
	0u dCEST.res
	0u rfCEST.res
	0u FArfCEST.res
}

subroutine cest_wasabi()
{
	dCEST
	10u FArfCEST:f1
	(10u fCEST):f1
	(rfCEST:sp2(currentpower) pCEST):f1
	1000u grad_ramp{25.000, 25.000, 25.000}
	4500u
	1000u grad_off
	10u fq8(receive):f1
	10u pl1:f1
}

subroutine cest_wasabiInc()
{
	0u fCEST.inc
	0u pCEST.inc
	0u dCEST.inc
	0u rfCEST.inc
	0u FArfCEST.inc
}
