; --------------------------------------- 32 bit Code ---------------------------------------
SEGMENT CODE32 USE32
ORG 0h

; --------------------------------------- One interrupt definition ---------------------------------------
intr00:
	IRETD

INCLUDE 'page32.asm'

; --------------------------------------- Entry Point ---------------------------------------
Start32:
	mov     ax,stack32_idx          
	mov     ss,ax                   
	mov     esp,stack32_end  
	mov     ax,data32_idx           
	mov     ds,ax
	mov     es,ax
	mov     ax,data16_idx
	mov     gs,ax
	mov     fs,ax

; --------------------------------------- Data stuff ---------------------------------------
	mov eax,1
	mov [ds:d32],eax
	mov ebx,[ds:d32]

; --------------------------------------- Interrupt Test ---------------------------------------
;	int 0;

; --------------------------------------- LLDT ---------------------------------------
	mov ax,ldt_idx
	lldt ax
	mov ax,data32_ldt_idx
	mov gs,ax
	push ds
	pop gs 

; --------------------------------------- Page Tests---------------------------------------
	call InitPageTable32a
	mov edx,PageDir32
	mov CR3,edx
	mov eax,cr4
	bts eax,4
	mov cr4,eax
	mov eax, cr0
	or eax,80000000h
	mov cr0, eax
	; Paging is now enabled
	nop
	nop
	nop
	; Disable Paging
	mov eax, cr0 ; Read CR0.
	and eax,7FFFFFFFh; Set PE=0
	mov cr0, eax ; Write CR0.

; --------------------------------------- Prepare Long Mode ---------------------------------------
    call InitPageTable642
	xchg bx,bx ; BOCHS magic breakpoint
; Enable PAE
    mov eax, cr4
    bts eax, 5
    mov cr4, eax
    
	; Load new page table
    mov edx,LONGPAGEORGBASE
    mov cr3,edx
    
	; Enable Long Mode
    mov ecx, 0c0000080h ; EFER MSR number. 
    rdmsr ; Read EFER.
    bts eax, 8 ; Set LME=1.
    wrmsr ; Write EFER.
  
	; Enable Paging to activate Long Mode
    mov eax, cr0 ; Read CR0.
    or eax,80000000h ; Set PE=1.
    mov cr0, eax ; Write CR0.
	nop
	nop
	nop
        
	; We are now in Long Mode / Compatibility mode
    ; Jump to an 64-bit segment to enable 64-bit mode
    db 0eah
    PutLinearStart64 dd 0
    dw code64_idx

; --------------------------------------- Back from Long Mode ---------------------------------------
Back32:
; We are now in Compatibility mode again
	mov     ax,stack32_idx          
	mov     ss,ax                   
	mov     esp,stack32_end  
	mov     ax,data32_idx           
	mov     ds,ax
	mov     es,ax
	mov     ax,data16_idx
	mov     gs,ax
	mov     fs,ax

; Disable Paging to get out of Long Mode
	mov eax, cr0
	and eax,7fffffffh 
	mov cr0, eax
  
; Deactivate Long Mode
	mov ecx, 0c0000080h
	rdmsr
	btc eax, 8
	wrmsr
 
; Disable PAE
	mov eax, cr4
	btc eax, 5
	mov cr4, eax

; --------------------------------------- Back to Real mode ---------------------------------------
; = Give FS the abs32 segment
; To test unreal mode 
	mov ax,absd32_idx
	mov fs,ax

; Go back
	db 066h ; because we are in a 32bit segment
	db 0eah
	dw exit16
	dw code16_idx


