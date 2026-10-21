import { createContext, useContext, useState, useRef, useEffect, useCallback } from 'react';

const DialogContext = createContext(null);

export function DialogProvider({ children }) {
  const [dialogState, setDialogState] = useState(null);
  const [inputValue, setInputValue] = useState('');
  const primaryBtnRef = useRef(null);
  const inputRef = useRef(null);

  const closeDialog = useCallback((result) => {
    if (dialogState?.resolve) {
      dialogState.resolve(result);
    }
    setDialogState(null);
  }, [dialogState]);

  const confirm = useCallback((messageOrOptions) => {
    const opts = typeof messageOrOptions === 'string'
      ? { message: messageOrOptions }
      : (messageOrOptions || {});
    const isDestructive = opts.isDestructive ?? (
      /delete|cancel|remove/i.test(opts.message || '') ||
      /delete|cancel|remove/i.test(opts.title || '')
    );
    return new Promise((resolve) => {
      setDialogState({
        type: 'confirm',
        title: opts.title || (isDestructive ? 'Confirm Action' : 'Please Confirm'),
        message: opts.message || '',
        confirmText: opts.confirmText || (isDestructive ? 'Delete' : 'Confirm'),
        cancelText: opts.cancelText || 'Cancel',
        isDestructive,
        resolve,
      });
    });
  }, []);

  const prompt = useCallback((messageOrOptions, defaultVal = '') => {
    const opts = typeof messageOrOptions === 'string'
      ? { message: messageOrOptions, defaultValue: defaultVal }
      : (messageOrOptions || {});
    setInputValue(opts.defaultValue != null ? String(opts.defaultValue) : '');
    return new Promise((resolve) => {
      setDialogState({
        type: 'prompt',
        title: opts.title || 'Enter Value',
        message: opts.message || '',
        confirmText: opts.confirmText || 'Save',
        cancelText: opts.cancelText || 'Cancel',
        inputType: opts.inputType || 'text',
        isDestructive: false,
        resolve,
      });
    });
  }, []);

  const alert = useCallback((messageOrOptions) => {
    const opts = typeof messageOrOptions === 'string'
      ? { message: messageOrOptions }
      : (messageOrOptions || {});
    return new Promise((resolve) => {
      setDialogState({
        type: 'alert',
        title: opts.title || 'Notice',
        message: opts.message || '',
        confirmText: opts.confirmText || 'OK',
        resolve,
      });
    });
  }, []);

  useEffect(() => {
    if (!dialogState) return;

    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        closeDialog(dialogState.type === 'prompt' ? null : false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);

    // Focus input or primary button
    const timer = setTimeout(() => {
      if (dialogState.type === 'prompt' && inputRef.current) {
        inputRef.current.focus();
        inputRef.current.select();
      } else if (primaryBtnRef.current) {
        primaryBtnRef.current.focus();
      }
    }, 40);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      clearTimeout(timer);
    };
  }, [dialogState, closeDialog]);

  return (
    <DialogContext.Provider value={{ confirm, prompt, alert }}>
      {children}

      {dialogState && (
        <div
          onClick={() => closeDialog(dialogState.type === 'prompt' ? null : false)}
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0, 0, 0, 0.45)',
            backdropFilter: 'blur(3px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 99999,
            padding: 16,
          }}
        >
          <style>{`
            @keyframes pq-dialog-pop {
              from { opacity: 0; transform: scale(0.94) translateY(6px); }
              to { opacity: 1; transform: scale(1) translateY(0); }
            }
          `}</style>

          <div
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
            style={{
              background: '#FFFFFF',
              borderRadius: 16,
              width: '100%',
              maxWidth: 420,
              padding: '24px 26px',
              boxShadow: '0 12px 36px rgba(0, 0, 0, 0.16)',
              border: '1px solid #ECECEC',
              animation: 'pq-dialog-pop 0.18s cubic-bezier(0.16, 1, 0.3, 1) both',
            }}
          >
            <h3
              style={{
                fontSize: 17,
                fontWeight: 700,
                color: dialogState.isDestructive ? '#DC2626' : '#1A1A1A',
                margin: '0 0 10px',
              }}
            >
              {dialogState.title}
            </h3>

            <p
              style={{
                fontSize: 13.5,
                color: '#555',
                lineHeight: 1.5,
                margin: 0,
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-word',
              }}
            >
              {dialogState.message}
            </p>

            {dialogState.type === 'prompt' && (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  closeDialog(inputValue);
                }}
                style={{ marginTop: 14 }}
              >
                <input
                  ref={inputRef}
                  type={dialogState.inputType}
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  style={{
                    width: '100%',
                    border: '1.5px solid #E5E5E5',
                    borderRadius: 10,
                    padding: '10px 14px',
                    fontSize: 14,
                    outline: 'none',
                    background: '#fff',
                  }}
                />
              </form>
            )}

            <div
              style={{
                display: 'flex',
                justifyContent: 'flex-end',
                gap: 10,
                marginTop: 22,
              }}
            >
              {dialogState.type !== 'alert' && (
                <button
                  type="button"
                  onClick={() => closeDialog(dialogState.type === 'prompt' ? null : false)}
                  style={{
                    background: '#fff',
                    color: '#555',
                    border: '1px solid #E5E5E5',
                    borderRadius: 10,
                    padding: '10px 18px',
                    fontSize: 13,
                    fontWeight: 600,
                    cursor: 'pointer',
                    boxShadow: 'none',
                    width: 'auto',
                  }}
                >
                  {dialogState.cancelText}
                </button>
              )}

              <button
                ref={primaryBtnRef}
                type="button"
                onClick={() => {
                  if (dialogState.type === 'prompt') {
                    closeDialog(inputValue);
                  } else if (dialogState.type === 'confirm') {
                    closeDialog(true);
                  } else {
                    closeDialog(true);
                  }
                }}
                style={{
                  background: dialogState.isDestructive
                    ? 'linear-gradient(135deg, #EF4444, #DC2626)'
                    : 'linear-gradient(135deg, #F5765C, #E8450A)',
                  color: '#fff',
                  border: 'none',
                  borderRadius: 10,
                  padding: '10px 20px',
                  fontSize: 13,
                  fontWeight: 600,
                  cursor: 'pointer',
                  boxShadow: dialogState.isDestructive
                    ? '0 4px 12px rgba(220, 38, 38, 0.28)'
                    : '0 4px 12px rgba(232, 69, 10, 0.25)',
                  width: 'auto',
                }}
              >
                {dialogState.confirmText}
              </button>
            </div>
          </div>
        </div>
      )}
    </DialogContext.Provider>
  );
}

export function useDialog() {
  const ctx = useContext(DialogContext);
  if (!ctx) {
    throw new Error('useDialog must be used within a DialogProvider');
  }
  return ctx;
}
