'use client';

import {
  createContext,
  useContext,
  useState,
  useCallback,
  useEffect,
  type ReactNode,
} from 'react';
import { usePathname } from 'next/navigation';

interface NavigationContextType {
  navigatingTo: string | null;
  startNavigation: (href: string) => void;
}

const NavigationContext = createContext<NavigationContextType>({
  navigatingTo: null,
  startNavigation: () => {},
});

export function useNavigation() {
  return useContext(NavigationContext);
}

export function NavigationProvider({ children }: { children: ReactNode }) {
  const [navigatingTo, setNavigatingTo] = useState<string | null>(null);
  const pathname = usePathname();

  const startNavigation = useCallback(
    (href: string) => {
      if (href !== pathname) {
        setNavigatingTo(href);
      }
    },
    [pathname],
  );

  useEffect(() => {
    setNavigatingTo(null);
  }, [pathname]);

  return (
    <NavigationContext.Provider value={{ navigatingTo, startNavigation }}>
      {navigatingTo && <ProgressBar />}
      {children}
    </NavigationContext.Provider>
  );
}

function ProgressBar() {
  return (
    <div className='fixed left-0 right-0 top-0 z-[9999] h-[3px] overflow-hidden bg-primary/20'>
      <div className='h-full animate-progress bg-primary' />
    </div>
  );
}
