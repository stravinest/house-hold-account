'use client';

import { useState, useRef } from 'react';
import { X, Upload, FileSpreadsheet, AlertTriangle, CheckCircle, Download } from 'lucide-react';
import { parseImportFile, autoMapColumns, mapRowsToPreview, generateSampleExcel } from '@/lib/utils/excel';
import { importTransactions } from '@/lib/actions/excel';
import type { ColumnMapping, ImportPreviewRow, ImportResult } from '@/lib/types/excel';
import { cn } from '@/lib/utils';
import { formatAmount } from '@/lib/utils/format';

type Step = 'upload' | 'mapping' | 'preview' | 'result';

interface ImportPanelProps {
  open: boolean;
  onClose: () => void;
  ledgerId: string;
  onSuccess: () => void;
}

const MAPPING_FIELDS: { key: keyof ColumnMapping; label: string; required: boolean }[] = [
  { key: 'date', label: '날짜', required: true },
  { key: 'type', label: '유형', required: true },
  { key: 'amount', label: '금액', required: true },
  { key: 'description', label: '제목', required: true },
  { key: 'category', label: '카테고리', required: false },
  { key: 'paymentMethod', label: '결제수단', required: false },
  { key: 'memo', label: '메모', required: false },
];

export function ImportPanel({ open, onClose, ledgerId, onSuccess }: ImportPanelProps) {
  const [step, setStep] = useState<Step>('upload');
  const [headers, setHeaders] = useState<string[]>([]);
  const [rows, setRows] = useState<string[][]>([]);
  const [mapping, setMapping] = useState<ColumnMapping>({
    date: null,
    type: null,
    amount: null,
    description: null,
    category: null,
    paymentMethod: null,
    memo: null,
  });
  const [previewRows, setPreviewRows] = useState<ImportPreviewRow[]>([]);
  const [createMissingCategories, setCreateMissingCategories] = useState(true);
  const [matchPaymentMethods, setMatchPaymentMethods] = useState(true);
  const [importing, setImporting] = useState(false);
  const [result, setResult] = useState<ImportResult | null>(null);
  const [error, setError] = useState('');
  const [dragOver, setDragOver] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const resetState = () => {
    setStep('upload');
    setHeaders([]);
    setRows([]);
    setMapping({ date: null, type: null, amount: null, description: null, category: null, paymentMethod: null, memo: null });
    setPreviewRows([]);
    setCreateMissingCategories(true);
    setMatchPaymentMethods(true);
    setImporting(false);
    setResult(null);
    setError('');
    setDragOver(false);
    setTruncatedWarning('');
  };

  const handleClose = () => {
    resetState();
    onClose();
  };

  const [truncatedWarning, setTruncatedWarning] = useState('');

  const processFile = async (file: File) => {
    setError('');
    setTruncatedWarning('');
    try {
      const parsed = await parseImportFile(file);
      setHeaders(parsed.headers);
      setRows(parsed.rows);

      if (parsed.truncated) {
        setTruncatedWarning(`데이터가 5,000건을 초과하여 처음 5,000건만 가져옵니다.`);
      }

      const autoMapping = autoMapColumns(parsed.headers);
      setMapping(autoMapping);
      setStep('mapping');
    } catch (e: any) {
      setError(e.message || '파일을 읽을 수 없습니다.');
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) processFile(file);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    const file = e.dataTransfer.files?.[0];
    if (file) processFile(file);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(true);
  };

  const handleDragLeave = () => {
    setDragOver(false);
  };

  const handleMappingConfirm = () => {
    if (mapping.date === null || mapping.amount === null || mapping.description === null) {
      setError('날짜, 금액, 제목 컬럼은 필수입니다.');
      return;
    }
    const selectedIndices = Object.values(mapping).filter((v): v is number => v !== null);
    if (new Set(selectedIndices).size !== selectedIndices.length) {
      setError('같은 컬럼을 여러 필드에 매핑할 수 없습니다.');
      return;
    }
    setError('');
    const preview = mapRowsToPreview(rows, mapping);
    setPreviewRows(preview);
    setStep('preview');
  };

  const handleImport = async () => {
    const validRows = previewRows.filter((r) => !r.error);
    if (validRows.length === 0) {
      setError('가져올 수 있는 유효한 데이터가 없습니다.');
      return;
    }

    setImporting(true);
    setError('');

    try {
      const transactions = validRows.map((r) => ({
        type: r.type,
        amount: r.amount,
        description: r.description,
        date: r.date,
        categoryName: r.category,
        paymentMethodName: r.paymentMethod,
        memo: r.memo,
      }));

      const importResult = await importTransactions(ledgerId, transactions, {
        createMissingCategories,
        matchPaymentMethods,
      });

      setResult(importResult);
      setStep('result');

      if (importResult.success > 0) {
        onSuccess();
      }
    } catch {
      setError('가져오기 중 오류가 발생했습니다.');
    } finally {
      setImporting(false);
    }
  };

  if (!open) return null;

  return (
    <div className='fixed inset-0 z-50 flex items-center justify-center'>
      <div className='fixed inset-0 bg-black/50' onClick={handleClose} />
      <div className='relative z-10 flex max-h-[90vh] w-full max-w-[600px] flex-col rounded-[20px] bg-white shadow-xl'>
        {/* Header */}
        <div className='flex items-center justify-between border-b border-separator px-6 py-[18px]'>
          <h2 className='text-lg font-bold text-on-surface'>
            {step === 'upload' && '파일 가져오기'}
            {step === 'mapping' && '컬럼 매핑'}
            {step === 'preview' && '미리보기'}
            {step === 'result' && '가져오기 결과'}
          </h2>
          <button
            onClick={handleClose}
            className='flex h-8 w-8 items-center justify-center rounded-full hover:bg-surface-container'
          >
            <X size={18} className='text-on-surface-variant' />
          </button>
        </div>

        {/* Body */}
        <div className='flex flex-col gap-4 overflow-y-auto px-6 py-5'>
          {/* Step 1: Upload */}
          {step === 'upload' && (
            <>
            <div
              onDrop={handleDrop}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onClick={() => fileInputRef.current?.click()}
              className={cn(
                'flex cursor-pointer flex-col items-center gap-3 rounded-[16px] border-2 border-dashed py-12 transition-colors',
                dragOver
                  ? 'border-primary bg-primary/5'
                  : 'border-[#E0E0E0] hover:border-primary/50 hover:bg-surface',
              )}
            >
              <div className='flex h-12 w-12 items-center justify-center rounded-full bg-primary/10'>
                <Upload size={24} className='text-primary' />
              </div>
              <div className='text-center'>
                <p className='text-sm font-medium text-on-surface'>
                  파일을 드래그하거나 클릭하여 업로드
                </p>
                <p className='mt-1 text-xs text-on-surface-variant'>
                  .xlsx, .csv 파일 (최대 5MB, 5,000건)
                </p>
              </div>
              <input
                ref={fileInputRef}
                type='file'
                accept='.xlsx,.csv,.xls'
                onChange={handleFileSelect}
                className='hidden'
              />
            </div>
            <div className='flex items-center justify-between'>
              <p className='text-xs text-on-surface-variant'>
                처음이라면 샘플 파일을 참고하세요. 입력 안내가 포함되어 있습니다.
              </p>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  generateSampleExcel();
                }}
                className='flex shrink-0 items-center gap-2 rounded-[10px] border border-[#E0E0E0] px-4 py-2.5 text-sm font-medium text-on-surface-variant transition-colors hover:bg-surface-container'
              >
                <Download size={16} />
                샘플 다운로드
              </button>
            </div>
            </>
          )}

          {/* Step 2: Column Mapping */}
          {step === 'mapping' && (
            <>
              <div className='flex items-center gap-2 rounded-[10px] bg-[#FFF8E1] px-3 py-2'>
                <FileSpreadsheet size={16} className='text-[#F57F17]' />
                <p className='text-sm text-[#F57F17]'>
                  {headers.length}개 컬럼, {rows.length}개 행 감지됨
                </p>
              </div>
              {truncatedWarning && (
                <div className='flex items-center gap-2 rounded-[10px] bg-[#FFF3E0] px-3 py-2'>
                  <AlertTriangle size={16} className='shrink-0 text-[#E65100]' />
                  <p className='text-sm text-[#E65100]'>{truncatedWarning}</p>
                </div>
              )}

              <div className='flex flex-col gap-3'>
                {MAPPING_FIELDS.map((field) => (
                  <div key={field.key} className='flex items-center gap-3'>
                    <span className='w-20 text-sm text-on-surface-variant'>
                      {field.label}
                      {field.required && <span className='text-expense'>*</span>}
                    </span>
                    <select
                      value={mapping[field.key] ?? ''}
                      onChange={(e) =>
                        setMapping({
                          ...mapping,
                          [field.key]: e.target.value === '' ? null : Number(e.target.value),
                        })
                      }
                      className='h-[38px] flex-1 rounded-[8px] border border-[#E8E8E8] bg-[#F8F9FA] px-3 text-sm outline-none focus:border-primary'
                    >
                      <option value=''>-- 선택 안함 --</option>
                      {headers.map((h, idx) => (
                        <option key={idx} value={idx}>
                          {h}
                        </option>
                      ))}
                    </select>
                  </div>
                ))}
              </div>

              {/* Options */}
              <div className='flex flex-col gap-2 rounded-[10px] bg-[#F5F6F5] p-3'>
                <label className='flex cursor-pointer items-center gap-2 text-sm text-on-surface-variant'>
                  <input
                    type='checkbox'
                    checked={createMissingCategories}
                    onChange={(e) => setCreateMissingCategories(e.target.checked)}
                    className='h-4 w-4 rounded accent-primary'
                  />
                  없는 카테고리 자동 생성
                </label>
                <label className='flex cursor-pointer items-center gap-2 text-sm text-on-surface-variant'>
                  <input
                    type='checkbox'
                    checked={matchPaymentMethods}
                    onChange={(e) => setMatchPaymentMethods(e.target.checked)}
                    className='h-4 w-4 rounded accent-primary'
                  />
                  결제수단 자동 매칭
                </label>
              </div>
            </>
          )}

          {/* Step 3: Preview */}
          {step === 'preview' && (
            <>
              {/* Summary */}
              <div className='flex gap-3'>
                <div className='flex-1 rounded-[10px] bg-[#E8F5E9] px-3 py-2 text-center'>
                  <p className='text-lg font-bold text-[#2E7D32]'>
                    {previewRows.filter((r) => !r.error).length}
                  </p>
                  <p className='text-xs text-[#2E7D32]/70'>유효</p>
                </div>
                <div className='flex-1 rounded-[10px] bg-[#FFF3E0] px-3 py-2 text-center'>
                  <p className='text-lg font-bold text-[#E65100]'>
                    {previewRows.filter((r) => r.error).length}
                  </p>
                  <p className='text-xs text-[#E65100]/70'>오류</p>
                </div>
                <div className='flex-1 rounded-[10px] bg-[#F5F6F5] px-3 py-2 text-center'>
                  <p className='text-lg font-bold text-on-surface'>{previewRows.length}</p>
                  <p className='text-xs text-on-surface-variant'>전체</p>
                </div>
              </div>

              {/* Table */}
              <div className='max-h-[300px] overflow-auto rounded-[10px] border border-[#E8E8E8]'>
                <table className='w-full text-sm'>
                  <thead className='sticky top-0 bg-[#F5F6F5]'>
                    <tr>
                      <th className='px-3 py-2 text-left text-xs font-medium text-on-surface-variant'>행</th>
                      <th className='px-3 py-2 text-left text-xs font-medium text-on-surface-variant'>날짜</th>
                      <th className='px-3 py-2 text-left text-xs font-medium text-on-surface-variant'>유형</th>
                      <th className='px-3 py-2 text-right text-xs font-medium text-on-surface-variant'>금액</th>
                      <th className='px-3 py-2 text-left text-xs font-medium text-on-surface-variant'>제목</th>
                      <th className='px-3 py-2 text-left text-xs font-medium text-on-surface-variant'>상태</th>
                    </tr>
                  </thead>
                  <tbody>
                    {previewRows.slice(0, 50).map((row) => (
                      <tr
                        key={row.rowIndex}
                        className={cn(
                          'border-t border-[#F0F0F0]',
                          row.error && 'bg-expense/5',
                        )}
                      >
                        <td className='px-3 py-2 text-xs text-on-surface-variant'>{row.rowIndex}</td>
                        <td className='px-3 py-2 text-xs'>{row.date}</td>
                        <td className='px-3 py-2 text-xs'>
                          {row.type === 'income' ? '수입' : row.type === 'expense' ? '지출' : '자산'}
                        </td>
                        <td className='px-3 py-2 text-right text-xs font-medium'>
                          {formatAmount(row.amount)}
                        </td>
                        <td className='max-w-[140px] truncate px-3 py-2 text-xs'>{row.description}</td>
                        <td className='px-3 py-2'>
                          {row.error ? (
                            <span className='flex items-center gap-1 text-xs text-expense'>
                              <AlertTriangle size={12} />
                              {row.error}
                            </span>
                          ) : (
                            <span className='flex items-center gap-1 text-xs text-[#2E7D32]'>
                              <CheckCircle size={12} />
                              정상
                            </span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                {previewRows.length > 50 && (
                  <div className='bg-[#F5F6F5] px-3 py-2 text-center text-xs text-on-surface-variant'>
                    외 {previewRows.length - 50}건 더...
                  </div>
                )}
              </div>
            </>
          )}

          {/* Step 4: Result */}
          {step === 'result' && result && (
            <div className='flex flex-col items-center gap-4 py-4'>
              <div className='flex h-16 w-16 items-center justify-center rounded-full bg-[#E8F5E9]'>
                <CheckCircle size={32} className='text-[#2E7D32]' />
              </div>
              <p className='text-lg font-bold text-on-surface'>가져오기 완료</p>
              <div className='flex w-full gap-3'>
                <div className='flex-1 rounded-[10px] bg-[#E8F5E9] px-3 py-3 text-center'>
                  <p className='text-xl font-bold text-[#2E7D32]'>{result.success}</p>
                  <p className='text-xs text-[#2E7D32]/70'>성공</p>
                </div>
                <div className='flex-1 rounded-[10px] bg-[#FFF3E0] px-3 py-3 text-center'>
                  <p className='text-xl font-bold text-[#E65100]'>{result.skipped}</p>
                  <p className='text-xs text-[#E65100]/70'>중복 건너뜀</p>
                </div>
                <div className='flex-1 rounded-[10px] bg-[#FFEBEE] px-3 py-3 text-center'>
                  <p className='text-xl font-bold text-expense'>{result.failed}</p>
                  <p className='text-xs text-expense/70'>실패</p>
                </div>
              </div>
              {result.errors.length > 0 && (
                <div className='w-full rounded-[10px] bg-[#FFF8E1] p-3'>
                  <p className='mb-1 text-sm font-medium text-[#F57F17]'>오류 상세</p>
                  {result.errors.map((err, idx) => (
                    <p key={idx} className='text-xs text-[#F57F17]'>
                      행 {err.row}: {err.message}
                    </p>
                  ))}
                </div>
              )}
            </div>
          )}

          {error && <p className='text-sm text-expense'>{error}</p>}
        </div>

        {/* Footer */}
        <div className='flex items-center justify-end gap-3 border-t border-separator px-6 py-4'>
          {step === 'mapping' && (
            <>
              <button
                onClick={() => setStep('upload')}
                className='h-11 rounded-[10px] px-5 text-sm font-semibold text-on-surface-variant hover:bg-surface-container'
              >
                이전
              </button>
              <button
                onClick={handleMappingConfirm}
                className='h-11 rounded-[10px] bg-primary px-6 text-sm font-semibold text-white transition-colors hover:bg-primary/90'
              >
                다음
              </button>
            </>
          )}
          {step === 'preview' && (
            <>
              <button
                onClick={() => setStep('mapping')}
                className='h-11 rounded-[10px] px-5 text-sm font-semibold text-on-surface-variant hover:bg-surface-container'
              >
                이전
              </button>
              <button
                onClick={handleImport}
                disabled={importing}
                className='flex h-11 items-center gap-2 rounded-[10px] bg-primary px-6 text-sm font-semibold text-white transition-colors hover:bg-primary/90 disabled:opacity-50'
              >
                <Upload size={16} />
                {importing ? '가져오는 중...' : `${previewRows.filter((r) => !r.error).length}건 가져오기`}
              </button>
            </>
          )}
          {step === 'result' && (
            <button
              onClick={handleClose}
              className='h-11 rounded-[10px] bg-primary px-6 text-sm font-semibold text-white transition-colors hover:bg-primary/90'
            >
              완료
            </button>
          )}
          {step === 'upload' && (
            <button
              onClick={handleClose}
              className='h-11 rounded-[10px] px-5 text-sm font-semibold text-on-surface-variant hover:bg-surface-container'
            >
              취소
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
