NAME "5 АК"
;Подпрограмма вычисления сумм по столбцам матрицы
.386
OPTION casemap: none
.MODEL flat, stdcall

INCLUDE /masm32/include/kernel32.inc
INCLUDE /masm32/include/msvcrt.inc
INCLUDELIB /masm32/lib/kernel32.lib
INCLUDELIB /masm32/lib/msvcrt.lib

.CONST
	n = 100 ;максимальный размер

Matrix STRUC
	name_matrix BYTE ?
	row_count BYTE ?
	column_count BYTE ?
	info SDWORD n * n dup(?)
Matrix ENDS

Summ_column PROTO :PTR Matrix
ToIndex_2 PROTO :BYTE, :BYTE, :BYTE ;функция смещения для двумерного массива
ToIndex_1 PROTO :BYTE ;функция смещения для одномерного массива
InputMatrix PROTO :PTR Matrix
PrintMatrix PROTO :PTR Matrix
Print_mass PROTO :BYTE, :SDWORD, :BYTE

.DATA
	endl BYTE 0ah, 0
	byte_inp BYTE "%hhu", 0
	sdword_inp BYTE "%d", 0
	size_prompt BYTE "Enter the number of %s in matrix %c: ", 0
	_i BYTE "rows", 0
	_j BYTE "columns", 0
	elem_prompt BYTE "%c[%hhu, %hhu] = ", 0	
	matrix_outp BYTE 0ah, "%c =", 0
	elem_outp BYTE 09h, "%d", 0
	result BYTE "Array column sums:", 0ah, 0
	matrix_error BYTE "The matrix size you entered is too %s, try again.", 0ah, 0
	_small BYTE "small", 0
	_big BYTE "big", 0
	dword_inp BYTE "%u", 0
	arr_start BYTE " %c{%d", 0
	arr_elem BYTE ", %d", 0
	arr_end BYTE "}", 0ah, 0

.DATA?
	a Matrix <>

.CODE
	main:
		MOV a.name_matrix, 'A'
		INVOKE InputMatrix, ADDR a  ;ввели матрицу
		.IF eax != -1
			INVOKE PrintMatrix, ADDR a  ;вывели матрицу
			INVOKE Summ_column, ADDR a  ;функция по заданию
			
		.ENDIF
		
		INVOKE crt__getch
		
		INVOKE ExitProcess, 0

		Print_mass Proc  mass_name:BYTE, mass_ptr:SDWORD, N:BYTE  ; вывод массива 
			PUSHAD
			MOV esi, mass_ptr
			MOV bl, 1
			INVOKE crt_printf, ADDR arr_start, mass_name, SDWORD PTR [esi]
			.WHILE bl < N
				INVOKE ToIndex_1, bl
				INVOKE crt_printf, ADDR arr_elem, SDWORD PTR [esi + eax]
				INC bl
			.ENDW
			INVOKE crt_printf, ADDR arr_end
			
			POPAD
			RET
		Print_mass ENDP

		Summ_column PROC matrix_ptr:PTR Matrix
			LOCAL column_count:BYTE, row_count:BYTE,  tmp_mass[n]: SDWORD, sum: SDWORD, i:BYTE, j: BYTE
			PUSHAD
			
			MOV esi, matrix_ptr
			MOV ch, [esi + Matrix.row_count]
			MOV cl, [esi + Matrix.column_count]
			MOV row_count, ch
			MOV column_count, cl

			INVOKE ToIndex_2, 0, 0, column_count
			MOV ebx, [esi + Matrix.info + eax]
			MOV i, 0 ;строки
			MOV j, 0 ;столбцы
			.REPEAT
				MOV sum, 0
				.REPEAT
					INVOKE ToIndex_2, i, j, column_count
					MOV ebx, [esi + Matrix.info + eax]
					ADD sum, ebx
									
					INC i ; переходим на новую строчку
					MOV cl, i
				.UNTIL cl == row_count
				
				
				INVOKE ToIndex_1, j
				MOV ebx, sum
				MOV tmp_mass[eax], ebx
				INC j ; переходим на новый столбец
				MOV cl, j
			.UNTIL cl == column_count

		
			INVOKE Print_mass, 'M', ADDR tmp_mass, cl			
			RET
		Summ_column ENDP
		
		ToIndex_2 PROC i:BYTE, j:BYTE, column_count:BYTE   ;функция смещения для двумерного массива
			PUSH dx
			MOVZX ax, i
			MUL column_count
			MOVZX dx, j
			ADD ax, dx
			MOV dx, 4
			MUL dx
			POP dx
			CWDE
			RET
		ToIndex_2 ENDP

		InputMatrix PROC matrix_ptr:PTR Matrix    ;ввод матрицы
			LOCAL column_count:BYTE, row_count:BYTE
			PUSHAD
			MOV esi, matrix_ptr
			INVOKE crt_printf, ADDR size_prompt, ADDR _i, [esi + Matrix.name_matrix]
			INVOKE crt_scanf, ADDR byte_inp, ADDR row_count
			INVOKE crt_printf, ADDR size_prompt, ADDR _j, [esi + Matrix.name_matrix]
			INVOKE crt_scanf, ADDR byte_inp, ADDR column_count
			.IF row_count < 2 && column_count < 2
				INVOKE crt_printf, ADDR matrix_error, ADDR _small
				POPAD
				MOV eax, -1
				RET
			.ELSEIF row_count > 100 || column_count > 100
				INVOKE crt_printf, ADDR matrix_error, ADDR _big
				POPAD
				MOV eax, -1
				RET
			.ENDIF
			MOV bh, 0
			.REPEAT
				MOV bl, 0
				.REPEAT
					INVOKE crt_printf, ADDR elem_prompt, [esi + Matrix.name_matrix], bh, bl
					INVOKE ToIndex_2, bh, bl, column_count
					INVOKE crt_scanf, ADDR sdword_inp, ADDR [esi + Matrix.info + eax]
					INC bl
				.UNTIL bl == column_count
				INC bh
			.UNTIL bh == row_count
			MOV [esi + Matrix.row_count], bh
			MOV [esi + Matrix.column_count], bl
			POPAD
			RET
		InputMatrix ENDP
		
		PrintMatrix PROC matrix_ptr:PTR Matrix             ;вывод матрицы
			LOCAL column_count:BYTE, row_count:BYTE
			PUSHAD
			MOV esi, matrix_ptr
			INVOKE crt_printf, ADDR matrix_outp, [esi + Matrix.name_matrix]
			MOV bh, [esi + Matrix.row_count]
			MOV bl, [esi + Matrix.column_count]
			MOV row_count, bh
			MOV column_count, bl
			MOV bh, 0
			.REPEAT
				MOV bl, 0
				.REPEAT
					INVOKE ToIndex_2, bh, bl, column_count
					INVOKE crt_printf, ADDR elem_outp, [esi + Matrix.info + eax]
					INC bl
				.UNTIL bl == column_count
				INVOKE crt_printf, ADDR endl
				INC bh
			.UNTIL bh == row_count
			POPAD
			RET
		PrintMatrix ENDP


		ToIndex_1 PROC ind:BYTE     ;функция смещения для одномерного массива
			PUSH dx
			MOVZX eax, ind
			MOV dl, 4
			MUL dl
			POP dx
			RET
		ToIndex_1 ENDP
END main
