;+
;; @brief This program fits a polynomial to the input data using IDL's
;; REGRESS function 
;; @author Brian L. Lee
;; @date 02Nov2012
;;
;; @param_in data_x:  a double-precision vector containing the x
;; values of the points to be fit
;; @param_in data_y:  a double-precision vector containing the y
;; values of the points to be fit
;; @param_in measure_errors:  a double-precision vector containing the
;; y-sigma values of the points to be fit
;; @param_in poly_order:  a long or int specifying the order of
;; polynomial to fit along with the step
;; @param_out chisq:  the total chi-squared of the resulting fit
;; @param_out yfit:  the modelled y points of the resulting fit
;-
function calc_polyfit_regress, $
                               data_x=data_x, $
                               data_y=data_y, $
                               measure_errors=measure_errors, $
                               poly_order=poly_order, $
                               chisq=chisq, $
                               yfit=yfit, $
                               plot_to_screen=plot_to_screen

;PRINT, SYSTIME(/UTC), "|Running calc_polyfit_regress"

;;=============================================================================
;;0.0. Check log file
;;=============================================================================
IF SIZE(log_lun, /TYPE) EQ 0 THEN BEGIN
    log_lun = -1l
ENDIF
;;=============================================================================
;;1.  Integrity checks on inputs
;;=============================================================================
;;Check that data_x, data_y, and measure_errors are double precision numbers
IF SIZE(data_x,/TYPE) NE 5 THEN BEGIN
    err_msg = SYSTIME(/UTC) + "|ERROR|CALC_POLYFIT_REGRESS|data_x is not double precision! " + STRTRIM(data_x, 2) + ")."
    PRINT, err_msg
    PRINTF, log_lun, err_msg
    SAVE, FILENAME='error_CALC_POLYFIT_REGRESS.sav', /ALL
    RETURN, err_msg
ENDIF
IF SIZE(data_y,/TYPE) NE 5 THEN BEGIN
    err_msg = SYSTIME(/UTC) + "|ERROR|CALC_POLYFIT_REGRESS|data_y is not double precision! " + STRTRIM(data_y, 2) + ")."
    PRINT, err_msg
    PRINTF, log_lun, err_msg
    SAVE, FILENAME='error_CALC_POLYFIT_REGRESS.sav', /ALL
    RETURN, err_msg
ENDIF
IF SIZE(measure_errors,/TYPE) NE 5 THEN BEGIN
    err_msg = SYSTIME(/UTC) + "|ERROR|CALC_POLYFIT_REGRESS|measure_errors is not double precision! " + STRTRIM(measure_errors, 2) + ")."
    PRINT, err_msg
    PRINTF, log_lun, err_msg
    SAVE, FILENAME='error_CALC_POLYFIT_REGRESS.sav', /ALL
    RETURN, err_msg
ENDIF
;;Check that data_x, data_y, and measure_errors are 1-D
data_x_size = SIZE(data_x)
IF data_x_size[0] EQ 1l THEN BEGIN
    data_x_length = data_x_size[1]
ENDIF
IF data_x_size[0] NE 1l THEN BEGIN    
    err_msg = SYSTIME(/UTC) + "|ERROR|CALC_POLYFIT_REGRESS|The specified data_x array is not 1-D (SIZE[0] is " + STRTRIM(data_x_size[0], 2) + ")."
    PRINT, err_msg
    PRINTF, log_lun, err_msg
    SAVE, FILENAME='error_CALC_POLYFIT_REGRESS.sav', /ALL
    RETURN, err_msg
ENDIF
data_y_size = SIZE(data_y)
IF data_y_size[0] EQ 1l THEN BEGIN
    data_y_length = data_y_size[1]
ENDIF
IF data_y_size[0] NE 1l THEN BEGIN    
    err_msg = SYSTIME(/UTC) + "|ERROR|CALC_POLYFIT_REGRESS|The specified data_y array is not 1-D (SIZE[0] is " + STRTRIM(data_y_size[0], 2) + ")."
    PRINT, err_msg
    PRINTF, log_lun, err_msg
    SAVE, FILENAME='error_CALC_POLYFIT_REGRESS.sav', /ALL
    RETURN, err_msg
ENDIF
measure_errors_size = SIZE(measure_errors)
IF measure_errors_size[0] EQ 1l THEN BEGIN
    measure_errors_length = measure_errors_size[1]
ENDIF
IF measure_errors_size[0] NE 1l THEN BEGIN    
    err_msg = SYSTIME(/UTC) + "|ERROR|CALC_POLYFIT_REGRESS|The specified measure_errors array is not 1-D (SIZE[0] is " + STRTRIM(measure_errors_size[0], 2) + ")."
    PRINT, err_msg
    PRINTF, log_lun, err_msg
    SAVE, FILENAME='error_CALC_POLYFIT_REGRESS.sav', /ALL
    RETURN, err_msg
ENDIF
;;Check that data_x, data_y, and measure_errors are matched in size
IF data_x_length NE data_y_length OR data_x_length NE measure_errors_length THEN BEGIN    
    err_msg = SYSTIME(/UTC) + "|ERROR|CALC_POLYFIT_REGRESS|The specified data_x, data_y, and measure_errors arrays are not matched in length."
    PRINT, err_msg
    PRINTF, log_lun, err_msg
    SAVE, FILENAME='error_CALC_POLYFIT_REGRESS.sav', /ALL
    RETURN, err_msg
ENDIF
;;=============================================================================
;;2.  Set up internal variables
;;=============================================================================
;;=============================================================================
;;2.1  Set up arrays to hold the best fit values
;;=============================================================================
;;Initialize the chi-squared that needs to be beaten
best_chisq=!values.f_infinity
;;=============================================================================
;;2.2  Form as many polynomial basis functions as needed based on the
;;ord (note regress provides the constant term itself, so we only need
;;to form the linear and higher basis functions here)
;;=============================================================================
poly_basis_matrix=dblarr(data_x_length,poly_order)
for ipoly=1,poly_order do begin
    poly_basis_matrix[*,ipoly-1]=(data_x)^ipoly
endfor
;;=============================================================================
;;2.3  Put the matrix in the correct shape to use in REGRESS.
;;=============================================================================
independent_matrix=transpose([[poly_basis_matrix]])
;;=============================================================================
;;3.  Do a least-squares fit for the polynomial order 
;;=============================================================================
coeff=regress(independent_matrix,data_y,const=c0,measure_errors=measure_errors,/DOUBLE)
;;=============================================================================
;;3.1  Evaluate the sum of the coeffs*basis vectors
;;=============================================================================
yfit_current=(dblarr(data_x_length)+c0)
for ipoly=1,poly_order do begin
    yfit_current=yfit_current+coeff[ipoly-1]*poly_basis_matrix[*,ipoly-1]
endfor
;;=============================================================================
;;3.2  Evaluate the total chi-squared
;;=============================================================================
chisq_current=total( ((yfit_current-data_y)/measure_errors)^2 )
;;=============================================================================
;;3.3  If this was the best fit so far, keep a record of it
;;=============================================================================
if finite(chisq_current) and chisq_current lt best_chisq then begin
    best_chisq=chisq_current
    yfit=yfit_current
endif
;;=============================================================================
;;3.4  Plot the fit if desired
;;=============================================================================
if keyword_set(plot_to_screen) then begin
    plot,data_x,data_y,psym=4,/ys
    oplot,data_x,yfit_current,psym=5,color=255
    legend,string(chisq_current)
endif
;;=============================================================================
;;4.  Return success.
;;=============================================================================
;;Return the best_chisq that was found
chisq=best_chisq
;;Return the fit coefficients
return,[c0,reform(coeff)]
end