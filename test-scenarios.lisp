(in-package #:vivace-graph-v2-test)

(defparameter *basic-concurrency-1* nil)
(defparameter *basic-concurrency-2* nil)
(defparameter *triple-2* nil)

(defun basic-concurrency-1 (&optional (store *store*))
  (let ((*store* store))
    (let ((thr1 (make-thread 
		 #'(lambda ()
		     (with-graph-transaction (*store* :timeout 10)
		       (let ((triple (add-triple "This" "is-a" "test" :graph "VGT")))
			 (format t "~%basic-concurrency-1 thr1: ~A: ~A~%" 
				 (triple-id triple) triple)
			 (setq *basic-concurrency-1* triple)
			 (sleep 3))))))
	  (thr2 (make-thread 
		 #'(lambda ()
		     (sleep 1)
		     (let ((triple (add-triple
				    "This" "is-a" "test" :graph "VGT")))
		       (if (triple? triple)
			   (format t "basic-concurrency-1 thr2: ~A: ~A~%" 
				   (triple-id triple) triple)
			   (format t "basic-concurrency-1 thr2: ~A~%" triple))
			   (if (triple-equal triple *basic-concurrency-1*)
			       (setq *basic-concurrency-1* triple)
			       (setq *basic-concurrency-1* nil)))))))
      (join-thread thr1)
      (join-thread thr2)
      (format t "basic-concurrency-1: ~A~%" *basic-concurrency-1*)
      *basic-concurrency-1*)))
    
(defun basic-concurrency-2 (&optional (store *store*))
  (let* ((*store* store)
	 (read-fn #'(lambda ()
		      (let ((*read-uncommitted* t))
			(sleep (random 2.0))
			(let ((triple (lookup-triple "This" "is-a" "test-2" "VGT")))
			  (if (triple? triple)
			      (format t "basic-concurrency-2 read-thr: ~A: ~A~%" 
				      (triple-id triple) triple)
			      (format t "basic-concurrency-2 read-thr: ~A~%" triple))
			  (push (list (current-thread) triple) 
				*basic-concurrency-2*))))))
    (let ((thr1 (make-thread 
		 #'(lambda ()
		     (with-graph-transaction (*store* :timeout 10)
		       (let ((triple (add-triple "This" "is-a" "test-2" :graph "VGT")))
			 (format t "~%basic-concurrency-2 thr1: ~A: ~A~%" 
				 (triple-id triple) triple)
			 (setq *triple-2* triple)
			 (sleep 3))))))
	  (thr2 (make-thread 
		 #'(lambda ()
		     (sleep 1)
		     (let ((triple (add-triple
				    "This" "is-a" "test-2" :graph "VGT")))
		       (if (triple? triple)
			   (format t "basic-concurrency-2 thr2: ~A: ~A~%" 
				   (triple-id triple) triple)
			   (format t "basic-concurrency-2 thr2: ~A~%" triple))
		       (push (list (current-thread) triple) *basic-concurrency-2*)))))
	  (thr3 (make-thread read-fn))
	  (thr4 (make-thread read-fn))
	  (thr5 (make-thread read-fn)))
      (join-thread thr1)
      (join-thread thr2)
      (join-thread thr3)
      (join-thread thr4)
      (join-thread thr5)
      (every #'(lambda (triple)
		 (triple-equal (second triple) *triple-2*))
	     *basic-concurrency-2*))))

(defun delete-undelete-test ()
  (let ((triple (add-triple "This" "is-a" "delete-undelete-test")))
    (let ((triple2 (lookup-triple "This" "is-a" "delete-undelete-test" "VGT")))
      (unless (triple-equal triple triple2)
	(error "~A not triple-equal to ~A" triple triple2))
      (delete-triple triple)
      (if (triple-deleted? triple)
	  (format t "~%Deleted ~A: ~A~%" triple (triple-deleted? triple))
	  (error "~A not deleted." triple))
      (let ((triple3 (lookup-triple "This" "is-a" "delete-undelete-test" "VGT")))
	(unless (null triple3)
	  (error "lookup-triple was not null: ~A!" triple3))
	(format t "lookup-triple: ~A~%" triple3))
      (let ((triple3 (lookup-triple "This" "is-a" "delete-undelete-test" "VGT"
				    :retrieve-deleted? t)))
	(unless (triple? triple3)
	  (error "lookup-triple :retrieve-deleted? t was null: ~A!" triple3))
	(format t "lookup-triple :retrieve-deleted? t: ~A~%" triple3))
      (add-triple "This" "is-a" "delete-undelete-test" :graph "VGT")
      (let ((triple3 (lookup-triple "This" "is-a" "delete-undelete-test" "VGT")))
	(when (triple? triple3)
	  (format t "undeleted ~A~%" triple3))
	(triple? triple3)))))




