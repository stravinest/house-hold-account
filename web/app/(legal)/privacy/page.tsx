import Link from 'next/link';

export default function PrivacyPolicyPage() {
  return (
    <main className='min-h-screen bg-white'>
      {/* Header */}
      <header className='bg-primary px-16 py-8'>
        <div className='mx-auto max-w-4xl'>
          <h1 className='text-3xl font-bold text-white'>개인정보처리방침</h1>
          <p className='mt-2 text-sm text-gray-200'>시행일자: 2026년 2월 6일</p>
        </div>
      </header>

      {/* Content */}
      <div className='mx-auto max-w-4xl px-16 py-16'>
        <p className='mb-8 text-base leading-relaxed text-gray-600'>
          우생가계부(이하 &apos;회사&apos;)는 「개인정보 보호법」, 「정보통신망 이용촉진 및
          정보보호 등에 관한 법률」 등 관련 법령에 따라 이용자의 개인정보를 보호하고, 이와
          관련한 고충을 신속하고 원활하게 처리할 수 있도록 다음과 같이 개인정보처리방침을
          수립·공개합니다.
        </p>

        {/* 제1조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제1조 (개인정보의 수집 및 이용 목적)
          </h2>
          <p className='mb-4 leading-relaxed text-gray-600'>
            회사는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는
            다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는
            「개인정보 보호법」 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할
            예정입니다.
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>1. 회원가입 및 관리</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 회원 가입의사 확인, 회원제 서비스 제공에 따른 본인 식별·인증
            <br />• 회원자격 유지·관리, 서비스 부정이용 방지
            <br />• 각종 고지·통지, 고충처리
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>2. 서비스 제공</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 가계부 데이터 저장 및 관리
            <br />• 공유 가계부 멤버 관리 및 초대 기능 제공
            <br />• SMS 자동수집 기능 제공 (안드로이드만 해당)
            <br />• 푸시 알림 발송
            <br />• 통계 및 차트 제공
            <br />• 홈 화면 위젯 데이터 제공
            <br />• 맞춤형 서비스 제공
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>
            3. 서비스 개선 및 신규 서비스 개발
          </h3>
          <p className='leading-relaxed text-gray-600'>
            • 서비스 이용 기록 및 접속 빈도 분석, 서비스 이용에 대한 통계
            <br />• 신규 서비스 개발 및 맞춤 서비스 제공
          </p>
        </section>

        {/* 제2조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제2조 (수집하는 개인정보의 항목)
          </h2>
          <p className='mb-4 leading-relaxed text-gray-600'>
            회사는 다음과 같은 개인정보 항목을 수집하고 있습니다.
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>1. 필수 수집 항목</h3>
          <p className='mb-2 font-medium text-gray-700'>회원가입 시</p>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 이메일 주소
            <br />• 비밀번호 (암호화하여 저장)
            <br />• 프로필 정보 (닉네임, 사용자 색상)
          </p>
          <p className='mb-2 font-medium text-gray-700'>Google 소셜 로그인 시</p>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 이메일 주소
            <br />• 프로필 정보 (이름, 프로필 사진)
            <br />• Google 계정 고유 ID
          </p>
          <p className='mb-2 font-medium text-gray-700'>서비스 이용 과정에서 수집되는 정보</p>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 거래 데이터 (금액, 날짜, 카테고리, 메모, 거래 유형)
            <br />• 결제수단 정보 (결제수단명, 자동수집 설정)
            <br />• 가계부 공유 정보 (멤버 ID, 권한)
            <br />• 이미지 데이터 (영수증 등 거래 관련 이미지)
            <br />• 푸시 알림 토큰 (FCM 토큰)
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>
            2. 선택 수집 항목 (사용자 동의 시)
          </h3>
          <p className='mb-2 font-medium text-gray-700'>
            SMS 자동수집 기능 사용 시 (안드로이드만 해당)
          </p>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • SMS 수신 내용 (금융거래 관련 SMS만 해당)
            <br />• SMS 발신자 정보
            <br />• SMS 수신 시각
          </p>
          <p className='mb-2 font-medium text-gray-700'>알림 기능 사용 시</p>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 기기 알림 권한 정보
            <br />• 알림 수신 설정 정보
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>3. 자동 수집 항목</h3>
          <p className='mb-2 font-medium text-gray-700'>
            서비스 이용 과정에서 자동으로 생성·수집되는 정보
          </p>
          <p className='leading-relaxed text-gray-600'>
            • 서비스 이용 기록
            <br />• 접속 로그
            <br />• 쿠키
            <br />• 기기 정보 (OS 버전, 앱 버전)
            <br />• IP 주소
          </p>
        </section>

        {/* 제3조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제3조 (개인정보의 수집 방법)
          </h2>
          <p className='leading-relaxed text-gray-600'>
            회사는 다음과 같은 방법으로 개인정보를 수집합니다.
            <br />
            <br />
            1. 회원가입 및 서비스 이용 과정에서 이용자가 직접 입력
            <br />
            2. Google 로그인 시 Google로부터 제공받음
            <br />
            3. SMS 자동수집 기능 사용 시 기기로부터 수집 (사용자 동의 후)
            <br />
            4. 서비스 이용 과정에서 자동으로 생성·수집
          </p>
        </section>

        {/* 제4조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제4조 (개인정보의 처리 및 보유 기간)
          </h2>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>1. 회원 정보</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 보유 기간: 회원 탈퇴 시까지
            <br />• 보유 근거: 서비스 제공을 위한 필수 정보
            <br />• 예외: 관련 법령에 따라 보존할 필요가 있는 경우 해당 기간 동안 보관
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>2. 거래 데이터</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 보유 기간: 회원 탈퇴 시 또는 이용자가 삭제 요청 시까지
            <br />• 보유 근거: 가계부 서비스 제공을 위한 필수 데이터
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>3. SMS 자동수집 데이터</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 보유 기간: 거래 생성 후 원본 SMS 즉시 삭제, 파싱된 거래 데이터만 보관
            <br />• 보유 근거: 사용자 편의를 위한 자동수집 기능
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>4. 로그 기록</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 보유 기간: 3개월
            <br />• 보유 근거: 서비스 개선 및 오류 수정
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>
            5. 관련 법령에 따른 보관
          </h3>
          <p className='mb-2 font-medium text-gray-700'>
            전자상거래 등에서의 소비자보호에 관한 법률
          </p>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 계약 또는 청약철회 등에 관한 기록: 5년
            <br />• 대금결제 및 재화 등의 공급에 관한 기록: 5년
            <br />• 소비자의 불만 또는 분쟁처리에 관한 기록: 3년
          </p>
          <p className='mb-2 font-medium text-gray-700'>통신비밀보호법</p>
          <p className='leading-relaxed text-gray-600'>
            • 서비스 이용 관련 로그 기록: 3개월
          </p>
        </section>

        {/* 제5조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제5조 (개인정보의 제3자 제공)
          </h2>
          <p className='leading-relaxed text-gray-600'>
            회사는 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다. 다만, 다음의
            경우에는 예외로 합니다.
            <br />
            <br />
            1. 이용자가 사전에 동의한 경우
            <br />
            2. 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라
            수사기관의 요구가 있는 경우
          </p>
        </section>

        {/* 제6조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제6조 (개인정보 처리 위탁)</h2>
          <p className='mb-4 leading-relaxed text-gray-600'>
            회사는 서비스 제공을 위하여 다음과 같이 개인정보 처리 업무를 외부 전문업체에
            위탁하여 운영하고 있습니다.
          </p>
          <div className='mb-4 overflow-x-auto'>
            <table className='w-full border-collapse border border-gray-300'>
              <thead>
                <tr className='bg-gray-100'>
                  <th className='border border-gray-300 px-4 py-2 text-left text-sm font-semibold'>
                    수탁업체
                  </th>
                  <th className='border border-gray-300 px-4 py-2 text-left text-sm font-semibold'>
                    위탁 업무 내용
                  </th>
                  <th className='border border-gray-300 px-4 py-2 text-left text-sm font-semibold'>
                    개인정보의 보유 및 이용기간
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    Supabase Inc.
                  </td>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    데이터베이스 저장 및 관리
                  </td>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    회원 탈퇴 시 또는 위탁계약 종료 시까지
                  </td>
                </tr>
                <tr>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    Google Firebase
                  </td>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    푸시 알림 발송, 인증 서비스
                  </td>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    회원 탈퇴 시 또는 위탁계약 종료 시까지
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <p className='leading-relaxed text-gray-600'>
            회사는 위탁계약 체결 시 「개인정보 보호법」 제26조에 따라 위탁업무 수행목적 외
            개인정보 처리금지, 기술적·관리적 보호조치, 재위탁 제한, 수탁자에 대한 관리·감독,
            손해배상 등 책임에 관한 사항을 계약서 등 문서에 명시하고, 수탁자가 개인정보를
            안전하게 처리하는지를 감독하고 있습니다.
          </p>
        </section>

        {/* 제7조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제7조 (이용자 및 법정대리인의 권리·의무 및 행사방법)
          </h2>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>1. 이용자의 권리</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            이용자는 회사에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수
            있습니다.
            <br />
            <br />• 개인정보 열람 요구
            <br />• 개인정보 정정·삭제 요구
            <br />• 개인정보 처리정지 요구
            <br />• 개인정보 처리에 대한 동의 철회
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>2. 권리 행사 방법</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            권리 행사는 회사에 대해 「개인정보 보호법」 시행령 제41조제1항에 따라 서면,
            전자우편, 모사전송(FAX) 등을 통하여 하실 수 있으며, 회사는 이에 대해 지체 없이
            조치하겠습니다.
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>
            3. 14세 미만 아동의 개인정보 보호
          </h3>
          <p className='leading-relaxed text-gray-600'>
            회사는 만 14세 미만 아동의 개인정보를 수집할 경우 법정대리인의 동의를 얻어야
            합니다. 회사는 법정대리인의 동의를 받기 위하여 필요한 최소한의 정보를 요구할 수
            있습니다.
          </p>
        </section>

        {/* 제8조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제8조 (개인정보의 파기)</h2>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>1. 파기 절차</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            이용자의 개인정보는 목적이 달성된 후 별도의 데이터베이스로 옮겨져 내부 방침 및
            기타 관련 법령에 의한 정보보호 사유에 따라 일정 기간 저장된 후 파기됩니다.
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>2. 파기 방법</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 전자적 파일 형태의 정보: 기록을 재생할 수 없는 기술적 방법을 사용하여 삭제
            <br />• 종이에 출력된 개인정보: 분쇄기로 분쇄하거나 소각
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>3. 파기 시기</h3>
          <p className='leading-relaxed text-gray-600'>
            • 회원 탈퇴 시: 지체 없이 파기
            <br />• 보유 기간이 만료된 경우: 보유 기간 종료일로부터 5일 이내
            <br />• 개인정보의 처리 목적 달성, 서비스 폐지 등: 해당 사유 발생일로부터 5일 이내
          </p>
        </section>

        {/* 제9조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제9조 (개인정보의 안전성 확보 조치)
          </h2>
          <p className='mb-4 leading-relaxed text-gray-600'>
            회사는 「개인정보 보호법」 제29조에 따라 다음과 같이 안전성 확보에 필요한
            기술적·관리적·물리적 조치를 하고 있습니다.
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>1. 기술적 조치</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 개인정보의 암호화: 비밀번호는 암호화되어 저장 및 관리, 중요 데이터는 전송 시
            SSL/TLS를 통한 암호화
            <br />• 해킹 등에 대비한 기술적 대책: 백신 프로그램 설치 및 주기적 업데이트, 외부로부터의
            무단 접근 통제
            <br />• 접근 기록의 보관 및 위변조 방지: 개인정보 처리 시스템 접속 기록을 최소 3개월
            이상 보관
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>2. 관리적 조치</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 내부관리계획의 수립 및 시행
            <br />• 개인정보 취급 직원의 최소화 및 교육
            <br />• 개인정보 접근 권한 관리
            <br />• 개인정보 처리시스템 접근 기록 보관 및 점검
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>3. 물리적 조치</h3>
          <p className='leading-relaxed text-gray-600'>
            • 전산실, 자료보관실 등의 접근통제
            <br />• 개인정보가 포함된 서류, 보조저장매체 등의 잠금장치 사용
          </p>
        </section>

        {/* 제10조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제10조 (개인정보 자동 수집 장치의 설치·운영 및 거부)
          </h2>
          <p className='mb-4 leading-relaxed text-gray-600'>
            회사는 개인화되고 맞춤화된 서비스를 제공하기 위해서 이용자의 정보를 저장하고
            수시로 불러오는 쿠키(cookie)를 사용합니다.
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>1. 쿠키의 사용 목적</h3>
          <p className='mb-4 leading-relaxed text-gray-600'>
            • 이용자의 접속 빈도나 방문 시간 등을 분석
            <br />• 이용자의 취향과 관심분야를 파악
            <br />• 각종 이벤트 참여 정도 및 방문 회수 파악
            <br />• 서비스 개선 및 맞춤형 서비스 제공
          </p>
          <h3 className='mb-2 text-lg font-semibold text-gray-800'>
            2. 쿠키의 설치·운영 및 거부
          </h3>
          <p className='leading-relaxed text-gray-600'>
            이용자는 쿠키 설치에 대한 선택권을 가지고 있습니다. 따라서 이용자는 웹 브라우저에서
            옵션을 설정함으로써 모든 쿠키를 허용하거나, 쿠키가 저장될 때마다 확인을 거치거나,
            아니면 모든 쿠키의 저장을 거부할 수도 있습니다. 다만, 쿠키의 저장을 거부할 경우
            로그인이 필요한 일부 서비스는 이용에 어려움이 있을 수 있습니다.
          </p>
        </section>

        {/* 제11조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제11조 (개인정보 보호책임자)
          </h2>
          <p className='mb-4 leading-relaxed text-gray-600'>
            회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한
            정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를
            지정하고 있습니다.
          </p>
          <div className='mb-4 rounded-lg bg-gray-50 p-4'>
            <p className='font-semibold text-gray-800'>개인정보 보호책임자</p>
            <p className='mt-1 text-gray-600'>• 성명: [담당자명 입력 필요]</p>
            <p className='text-gray-600'>• 직책: [직책 입력 필요]</p>
            <p className='text-gray-600'>• 연락처: [이메일 입력 필요]</p>
          </div>
          <p className='leading-relaxed text-gray-600'>
            이용자는 회사의 서비스를 이용하시면서 발생한 모든 개인정보 보호 관련 문의,
            불만처리, 피해구제 등에 관한 사항을 개인정보 보호책임자에게 문의하실 수 있습니다.
            회사는 이용자의 문의에 대해 지체 없이 답변 및 처리해드릴 것입니다.
          </p>
        </section>

        {/* 제12조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제12조 (권익침해 구제방법)</h2>
          <p className='mb-4 leading-relaxed text-gray-600'>
            이용자는 개인정보침해로 인한 구제를 받기 위하여 개인정보분쟁조정위원회,
            한국인터넷진흥원 개인정보침해신고센터 등에 분쟁해결이나 상담 등을 신청할 수
            있습니다.
          </p>
          <div className='space-y-3 rounded-lg bg-gray-50 p-4'>
            <div>
              <p className='font-semibold text-gray-800'>개인정보 침해신고센터</p>
              <p className='text-sm text-gray-600'>
                전화: (국번없이) 118 | 홈페이지: privacy.kisa.or.kr
              </p>
            </div>
            <div>
              <p className='font-semibold text-gray-800'>개인정보 분쟁조정위원회</p>
              <p className='text-sm text-gray-600'>
                전화: (국번없이) 1833-6972 | 홈페이지: www.kopico.go.kr
              </p>
            </div>
            <div>
              <p className='font-semibold text-gray-800'>대검찰청 사이버수사과</p>
              <p className='text-sm text-gray-600'>
                전화: (국번없이) 1301 | 홈페이지: www.spo.go.kr
              </p>
            </div>
            <div>
              <p className='font-semibold text-gray-800'>경찰청 사이버안전국</p>
              <p className='text-sm text-gray-600'>
                전화: (국번없이) 182 | 홈페이지: cyberbureau.police.go.kr
              </p>
            </div>
          </div>
        </section>

        {/* 제13조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제13조 (개인정보처리방침의 변경)
          </h2>
          <p className='leading-relaxed text-gray-600'>
            이 개인정보처리방침은 시행일로부터 적용되며, 법령 및 방침에 따른 변경내용의 추가,
            삭제 및 정정이 있는 경우에는 변경사항의 시행 7일 전부터 공지사항을 통하여 고지할
            것입니다.
          </p>
        </section>

        {/* 계정 및 데이터 삭제 */}
        <section
          id='account-deletion'
          className='mb-8 rounded-xl border-2 border-red-200 bg-red-50 p-6'
        >
          <h2 className='mb-4 text-2xl font-bold text-red-800'>
            계정 및 데이터 삭제 요청
          </h2>
          <p className='mb-4 text-base leading-relaxed text-gray-700'>
            <strong>우생가계부</strong> 이용자는 언제든지 계정 삭제를 요청할 수
            있습니다. 아래의 절차에 따라 계정 삭제를 진행해 주세요.
          </p>

          <h3 className='mb-3 text-lg font-semibold text-gray-900'>
            계정 삭제 방법
          </h3>
          <div className='mb-6 rounded-lg bg-white p-4'>
            <ol className='list-inside list-decimal space-y-2 text-gray-700'>
              <li>
                우생가계부 앱에 로그인합니다.
              </li>
              <li>
                <strong>설정</strong> 메뉴로 이동합니다.
              </li>
              <li>
                <strong>계정 삭제 (회원 탈퇴)</strong> 항목을 선택합니다.
              </li>
              <li>
                안내 사항을 확인한 후 <strong>삭제 확인</strong> 버튼을 눌러
                계정 삭제를 완료합니다.
              </li>
            </ol>
            <p className='mt-4 text-sm text-gray-600'>
              앱 내에서 삭제가 어려운 경우, 아래 이메일로 삭제를 요청하실 수
              있습니다.
            </p>
            <p className='mt-2 font-medium text-gray-800'>
              문의 이메일:{' '}
              <a
                href='mailto:stravinest@gmail.com'
                className='text-blue-600 underline'
              >
                stravinest@gmail.com
              </a>
            </p>
          </div>

          <h3 className='mb-3 text-lg font-semibold text-gray-900'>
            삭제되는 데이터
          </h3>
          <p className='mb-2 leading-relaxed text-gray-700'>
            계정 삭제 시 다음 데이터가 <strong>즉시 영구 삭제</strong>됩니다:
          </p>
          <ul className='mb-4 list-inside list-disc space-y-1 text-gray-700'>
            <li>계정 정보 (이메일, 프로필, 비밀번호)</li>
            <li>모든 거래 기록 (수입, 지출, 자산)</li>
            <li>카테고리 및 예산 설정</li>
            <li>결제수단 정보 및 자동수집 설정</li>
            <li>SMS 자동수집 데이터 (학습된 패턴 포함)</li>
            <li>푸시 알림 토큰 및 알림 설정</li>
            <li>업로드된 이미지 (영수증 등)</li>
          </ul>

          <h3 className='mb-3 text-lg font-semibold text-gray-900'>
            보관되는 데이터 및 보관 기간
          </h3>
          <p className='mb-2 leading-relaxed text-gray-700'>
            관련 법령에 따라 다음 데이터는 일정 기간 보관 후 파기됩니다:
          </p>
          <div className='overflow-x-auto'>
            <table className='w-full border-collapse border border-gray-300 bg-white'>
              <thead>
                <tr className='bg-gray-100'>
                  <th className='border border-gray-300 px-4 py-2 text-left text-sm font-semibold'>
                    데이터 유형
                  </th>
                  <th className='border border-gray-300 px-4 py-2 text-left text-sm font-semibold'>
                    보관 기간
                  </th>
                  <th className='border border-gray-300 px-4 py-2 text-left text-sm font-semibold'>
                    근거 법령
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    서비스 이용 관련 로그
                  </td>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    3개월
                  </td>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    통신비밀보호법
                  </td>
                </tr>
                <tr>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    소비자 불만/분쟁처리 기록
                  </td>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    3년
                  </td>
                  <td className='border border-gray-300 px-4 py-2 text-sm text-gray-600'>
                    전자상거래법
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <h3 className='mb-3 mt-6 text-lg font-semibold text-gray-900'>
            계정 삭제 없이 데이터만 삭제
          </h3>
          <p className='leading-relaxed text-gray-700'>
            계정을 유지하면서 특정 데이터만 삭제하고 싶은 경우, 앱 내에서 다음
            데이터를 직접 삭제할 수 있습니다:
          </p>
          <ul className='mt-2 list-inside list-disc space-y-1 text-gray-700'>
            <li>개별 거래 기록 삭제</li>
            <li>카테고리 삭제</li>
            <li>결제수단 삭제</li>
            <li>자동수집된 임시 거래 삭제</li>
            <li>업로드된 이미지 삭제</li>
          </ul>
          <p className='mt-2 text-sm text-gray-600'>
            위 항목 외에 추가 데이터 삭제가 필요한 경우{' '}
            <a
              href='mailto:stravinest@gmail.com'
              className='text-blue-600 underline'
            >
              stravinest@gmail.com
            </a>
            으로 문의해 주세요.
          </p>
        </section>

        {/* 부칙 */}
        <section className='mb-8 border-t border-gray-200 pt-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>부칙</h2>
          <p className='mb-4 leading-relaxed text-gray-600'>
            <strong>시행일자</strong>: 2026년 2월 6일
          </p>
          <p className='mb-4 leading-relaxed text-gray-600'>
            <strong>고지 의무</strong>: 현 개인정보처리방침 내용 추가, 삭제 및 수정이 있을
            시에는 개정 최소 7일 전부터 서비스 내 &apos;공지사항&apos;을 통해 고지할 것입니다.
          </p>
          <p className='font-semibold text-gray-800'>
            본 방침은 2026년 2월 6일부터 시행됩니다.
          </p>
        </section>

        {/* 홈으로 버튼 */}
        <div className='mt-12'>
          <Link
            href='/'
            className='inline-block rounded-xl bg-primary px-6 py-3 font-semibold text-white transition-colors hover:bg-primary/90'
          >
            홈으로 돌아가기
          </Link>
        </div>
      </div>
    </main>
  );
}
