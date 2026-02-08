export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div
      className='flex min-h-screen items-center justify-center py-20'
      style={{
        background: 'linear-gradient(180deg, #F0F7F1 0%, #FFFFFF 100%)',
      }}
    >
      {children}
    </div>
  );
}
