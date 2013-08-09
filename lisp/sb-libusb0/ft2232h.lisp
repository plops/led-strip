;; libusb code to upload data to a ft2232h chip in ft245 synchronous
;; fifo mode

(declaim (optimize (speed 0) (safety 3) (debug 3)))
#+nil
(eval-when (:compile-toplevel :execute :load-toplevel)
 (push #P"/home/martin/led-strip/lisp/sb-libusb0/" asdf:*central-registry*)
 #+nil (setf asdf:*central-registry* 
       '("c:/Users/martin/Desktop/stage/sb-libusb0/") ))
#.(require :sb-libusb0)

(defparameter *current-handle* nil)



#+nil
(defparameter *d*
  (car
   (sb-libusb0-internal::get-devices-by-ids :vendor-id #x0403
					    :product-id #x6010)))
#+nil
(sb-ext:run-program "/usr/bin/upload_morphic" '("/home/martin/led-strip/output_files/test.rbf"))

#+nil
(when *d*
 (defparameter *current-handle*
   (sb-libusb0-internal::usb-open *d*)))
; {n11,l12,r9,r11,r13,r14,p16,n16,l16,k16};
#+nil
(progn
  (sb-libusb0-internal::usb-close *current-handle*)
 (defparameter *current-handle* nil))



#+nil
(usbint::check
 (usbint::claim-interface* *current-handle* 1))

(defparameter *D2XX_MANAGER*
  '(( FT_DATA_BITS_7 7)
    ( FT_DATA_BITS_8 8)
    ( FT_STOP_BITS_1 0)
    ( FT_STOP_BITS_2 2)
    ( FT_PARITY_NONE 0)
    ( FT_PARITY_ODD 1)
    ( FT_PARITY_EVEN 2)
    ( FT_PARITY_MARK 3)
    ( FT_PARITY_SPACE 4)
    ( FT_FLOW_NONE 0)
    ( FT_FLOW_RTS_CTS 256)
    ( FT_FLOW_DTR_DSR 512)
    ( FT_FLOW_XON_XOFF 1024)
    ( FT_PURGE_RX 1)
    ( FT_PURGE_TX 2)
    ( FT_CTS 16)
    ( FT_DSR 32)
    ( FT_RI 64)
    ( FT_DCD 128)
    ( FT_OE 2)
    ( FT_PE 4)
    ( FT_FE 8)
    ( FT_BI 16)
    ( FT_EVENT_RXCHAR 1)
    ( FT_EVENT_MODEM_STATUS 2)
    ( FT_EVENT_LINE_STATUS 4)
    ( FT_EVENT_REMOVED 8)
    ( FT_FLAGS_OPENED 1)
    ( FT_FLAGS_HI_SPEED 2)
    ( FT_DEVICE_232B 0)
    ( FT_DEVICE_8U232AM 1)
    ( FT_DEVICE_UNKNOWN 3)
    ( FT_DEVICE_2232 4)
    ( FT_DEVICE_232R 5)
    ( FT_DEVICE_245R 5)
    ( FT_DEVICE_2232H 6)
    ( FT_DEVICE_4232H 7)
    ( FT_DEVICE_232H 8)
    ( FT_DEVICE_X_SERIES 9)
    ( FT_BITMODE_RESET 0)
    ( FT_BITMODE_ASYNC_BITBANG 1)
    ( FT_BITMODE_MPSSE 2)
    ( FT_BITMODE_SYNC_BITBANG 4)
    ( FT_BITMODE_MCU_HOST 8)
    ( FT_BITMODE_FAST_SERIAL 16)
    ( FT_BITMODE_CBUS_BITBANG 32)
    ( FT_BITMODE_SYNC_FIFO 64)
    ( FTDI_BREAK_OFF 0)
    ( FTDI_BREAK_ON 16384)))

(defun lookup-d2xx-manager (request)
 (cadr (assoc request *D2XX_MANAGER*)))

(defparameter *BM_REQUEST_TYPE*
  '((HOST_TO_DEVICE 0)
    (DEVICE_TO_HOST 128)
    (STANDARD 0)
    (CLASS 32)
    (VENDOR 64)
    (RESERVED 96)
    (DEVICE 0)
    (INTERFACE 1)
    (ENDPOINT 2)
    (OTHER 3)))

(defun lookup-request-type (type)
 (cadr (assoc type *BM_REQUEST_TYPE*)))

(defparameter *VENDOR_REQUEST*
  '((RESET 0)
    (MODEM_CTRL 1)
    (SET_FLOW_CONTROL 2)
    (SET_BAUD_RATE 3)
    (SET_DATA 4)
    (GET_MODEM_STATUS 5)
    (SET_EVENT_CHAR 6)
    (SET_ERROR_CHAR 7)
    (SET_LATENCY_TIMER 9)
    (GET_LATENCY_TIMER 10)
    (SET_BIT_MODE 11)
    (GET_BIT_MODE 12)
    (READ_EE 144)
    (WRITE_EE 145)
    (ERASE_EE 146)))

(defun lookup-vendor-request (request)
 (cadr (assoc request *VENDOR_REQUEST*)))

#+nil
(lookup-vendor-request 'SET_BIT_MODE)

#+nil
(defun read-word (offset)
  (declare (type (integer 0 1023) offset))
  
  )

  ;; int readWord(short offset)
  ;; {
  ;;   byte[] dataRead = new byte[2];
  ;;   int rc = -1;

  ;;   Log.d("FT_EE_Ctrl", "Entered ReadWord.");
  ;;   if (offset >= 1024)
  ;;   {
  ;;     return rc;
  ;;   }
  ;;   int wIndex = offset;

  ;;   this.mDevice.getConnection().controlTransfer(-64, 
  ;;     144, 
  ;;     0, 
  ;;     wIndex, 
  ;;     dataRead, 
  ;;     2, 
  ;;     0);

  ;;   int value = dataRead[1] & 0xFF;
  ;;   value <<= 8;
  ;;   value |= dataRead[0] & 0xFF;
  ;;   return value;
  ;; }

  ;; boolean writeWord(short offset, short value)
  ;; {
  ;;   int wValue = value & 0xFFFF;
  ;;   int wIndex = offset & 0xFFFF;
  ;;   int status = 0;
  ;;   boolean rc = false;

  ;;   Log.d("FT_EE_Ctrl", "Entered WriteWord.");
  ;;   if (offset >= 1024)
  ;;   {
  ;;     return rc;
  ;;   }

  ;;   status = this.mDevice.getConnection().controlTransfer(64, 
  ;;     145, 
  ;;     wValue, 
  ;;     wIndex, 
  ;;     null, 
  ;;     0, 
  ;;     0);

  ;;   if (status == 0) rc = true;

  ;;   return rc;
  ;; }




;; 2232h is type 6
(defun set-bit-mode (bitmode &key (mask #xff) (handle *current-handle*))
  (declare (type unsigned-byte mask bitmode))
  (unless (or (= bitmode 0) (= 0 (logand bitmode #x5f)))
    (let ((value (ash bitmode 8)))
      (setf value (logior value (logand mask #xff)))
      (sb-libusb0::control-msg nil
		   :handle handle
		   :request-type (lookup-request-type 'VENDOR)
		   :request (lookup-vendor-request 'SET_BIT_MODE)
		   :value value))))
#+nil
sb-libusb0-internal::LIBUSB_REQUEST_TYPE_VENDOR

;;#define FTDI_DEVICE_OUT_REQTYPE (LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE | LIBUSB_ENDPOINT_OUT)

#+nil
(let* ((l (loop for i below 512 collect #xff))
       (data (make-array (length l) :element-type '(unsigned-byte 8) :initial-contents l)))
 (sb-libusb0::with-usb-open *d*
   #+nil(usbint::check
     (usbint::claim-interface* sb-libusb0-internal:*current-handle* 1))
   
   (set-bit-mode (lookup-d2xx-manager 'FT_BITMODE_SYNC_FIFO)
		 :handle sb-libusb0-internal:*current-handle*)
   (sb-libusb0::bulk-write data :ep #x02 :handle sb-libusb0-internal:*current-handle*)))
#+nil
(set-bit-mode (lookup-d2xx-manager 'FT_BITMODE_RESET)
	      :handle *current-handle*)

;; this is generated by my working libftdi c program
;; type req val ind len
;; #x40 0  0      1   0  reset
;; #x40 3  #x04e2 513 0  baudrate
;; #x40 9  #x0002 1   0  setlatency
;; #x40 11 #x00ff 1   0  bitmode
;; #x40 0  #x0001 1   0
;; #x40 0  #x0002 1   0
;; #x40 11 #x40ff 1   0
;; bulk

(defun purge (&key (rx t) (tx t) (handle *current-handle*))
  (when rx 
    (sb-libusb0::control-msg nil
			     :handle handle
			     :request-type (lookup-request-type 'VENDOR)
			     :request (lookup-vendor-request 'RESET)
			     :value 1
			     :index 1))
    (when tx 
    (sb-libusb0::control-msg nil
			     :handle handle
			     :request-type (lookup-request-type 'VENDOR)
			     :request (lookup-vendor-request 'RESET)
			     :value 2
			     :index 1)))


(defun set-baudrate (&key (rate 921600) (handle *current-handle*))
  (let ((divisor (ecase rate
		   (300 10000)
		   (600 5000)
		   (1200 2500)
		   (2400 1250)
		   (4800 625)
	   (9600 16696)
	   (19200 32924)
	   (38400 49230)
	   (57600 52)
	   (115200 26)
	   (240400 13)
	   (460800 16390)
	   (921600 32771)
	   (t (break "I'm too lazy for this."))))))
  
  (sb-libusb0::control-msg nil
			   :handle handle
			   :request-type (lookup-request-type 'VENDOR)
			   :request (lookup-vendor-request 'SET_BAUD_RATE)
			   :value #x4e2
			   :index 513))
#+nil
(set-baudrate)

(defun set-latency (&key (latency 2) (handle *current-handle*))
  (sb-libusb0::control-msg nil
			   :handle handle
			   :request-type (lookup-request-type 'VENDOR)
			   :request (lookup-vendor-request 'SET_LATENCY_TIMER)
			   :value (logand latency 255)
			   :index 0))

#+nil
(set-latency)
