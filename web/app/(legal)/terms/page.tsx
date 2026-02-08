import Link from 'next/link';

export default function TermsOfServicePage() {
  return (
    <main className='min-h-screen bg-white'>
      {/* Header */}
      <header className='bg-primary px-16 py-8'>
        <div className='mx-auto max-w-4xl'>
          <h1 className='text-3xl font-bold text-white'>이용약관</h1>
          <p className='mt-2 text-sm text-gray-200'>시행일자: 2026년 2월 6일</p>
        </div>
      </header>

      {/* Content */}
      <div className='mx-auto max-w-4xl px-16 py-16'>
        {/* 제1조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제1조 (목적)</h2>
          <p className='leading-relaxed text-gray-600'>
            본 약관은 우생가계부(이하 &apos;서비스&apos;)를 이용함에 있어 회사와 이용자 간의
            권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.
          </p>
        </section>

        {/* 제2조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제2조 (정의)</h2>
          <p className='leading-relaxed text-gray-600'>
            1. &apos;서비스&apos;란 회사가 제공하는 가계부 관리 및 공유 애플리케이션을
            의미합니다.
            <br />
            2. &apos;이용자&apos;란 본 약관에 따라 회사가 제공하는 서비스를 이용하는 자를
            의미합니다.
            <br />
            3. &apos;가계부&apos;란 이용자가 생성한 수입, 지출, 자산 관리 데이터를 의미합니다.
            <br />
            4. &apos;공유 가계부&apos;란 여러 이용자가 함께 사용하는 가계부를 의미합니다.
            <br />
            5. &apos;회원&apos;이란 회사와 서비스 이용계약을 체결하고 회원 아이디를 부여받은
            자를 의미합니다.
          </p>
        </section>

        {/* 제3조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제3조 (약관의 효력 및 변경)
          </h2>
          <p className='leading-relaxed text-gray-600'>
            1. 본 약관은 서비스 화면에 게시하거나 기타의 방법으로 공지함으로써 효력이
            발생합니다.
            <br />
            2. 회사는 필요한 경우 관련 법령을 위배하지 않는 범위에서 본 약관을 변경할 수
            있습니다.
            <br />
            3. 회사가 약관을 변경할 경우에는 적용일자 및 변경사유를 명시하여 현행약관과 함께
            서비스 초기화면에 그 적용일자 7일 전부터 적용일자 전일까지 공지합니다.
            <br />
            4. 이용자가 변경된 약관에 동의하지 않을 경우, 서비스 이용을 중단하고 탈퇴할 수
            있습니다.
          </p>
        </section>

        {/* 제4조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제4조 (회원가입)</h2>
          <p className='leading-relaxed text-gray-600'>
            1. 이용자는 회사가 정한 가입 양식에 따라 회원정보를 기입한 후 본 약관에 동의한다는
            의사표시를 함으로써 회원가입을 신청합니다.
            <br />
            2. 회사는 제1항과 같이 회원으로 가입할 것을 신청한 이용자 중 다음 각 호에 해당하지
            않는 한 회원으로 등록합니다.
            <br />
            &nbsp;&nbsp;- 가입신청자가 본 약관에 의하여 이전에 회원자격을 상실한 적이 있는 경우
            <br />
            &nbsp;&nbsp;- 실명이 아니거나 타인의 명의를 이용한 경우
            <br />
            &nbsp;&nbsp;- 허위의 정보를 기재하거나, 회사가 제시하는 내용을 기재하지 않은 경우
            <br />
            &nbsp;&nbsp;- 만 14세 미만 아동이 법정대리인의 동의를 얻지 아니한 경우
            <br />
            &nbsp;&nbsp;- 이용자의 귀책사유로 인하여 승인이 불가능하거나 기타 규정한 제반
            사항을 위반하며 신청하는 경우
          </p>
        </section>

        {/* 제5조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제5조 (서비스의 제공 및 변경)
          </h2>
          <p className='leading-relaxed text-gray-600'>
            1. 회사는 다음과 같은 서비스를 제공합니다.
            <br />
            &nbsp;&nbsp;- 수입, 지출, 자산 기록 및 관리
            <br />
            &nbsp;&nbsp;- 가계부 공유 및 멤버 관리
            <br />
            &nbsp;&nbsp;- 카테고리 및 예산 관리
            <br />
            &nbsp;&nbsp;- 통계 및 차트 제공
            <br />
            &nbsp;&nbsp;- SMS 자동수집 기능 (안드로이드만 해당)
            <br />
            &nbsp;&nbsp;- 푸시 알림 서비스
            <br />
            &nbsp;&nbsp;- 홈 화면 위젯 기능
            <br />
            &nbsp;&nbsp;- 기타 회사가 추가 개발하거나 제휴계약 등을 통해 제공하는 일체의 서비스
            <br />
            <br />
            2. 회사는 서비스의 내용을 변경할 경우 변경 사유 및 내용을 서비스 화면에
            공지합니다.
            <br />
            3. 회사는 상당한 이유가 있는 경우 운영상, 기술상의 필요에 따라 제공하고 있는
            서비스를 변경할 수 있습니다.
          </p>
        </section>

        {/* 제6조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제6조 (서비스의 중단)</h2>
          <p className='leading-relaxed text-gray-600'>
            1. 회사는 다음 각 호에 해당하는 경우 서비스 제공을 일시적으로 중단할 수 있습니다.
            <br />
            &nbsp;&nbsp;- 정보통신설비의 보수, 점검, 교체 및 고장, 통신의 두절 등의 사유가
            발생한 경우
            <br />
            &nbsp;&nbsp;- 서비스 이용의 폭주 등으로 정상적인 서비스 이용에 지장이 있는 경우
            <br />
            &nbsp;&nbsp;- 기타 불가항력적 사유가 있는 경우
            <br />
            <br />
            2. 회사는 국가비상사태, 정전, 서비스 설비의 장애 또는 서비스 이용의 폭주 등으로
            정상적인 서비스 이용에 지장이 있는 때에는 서비스의 전부 또는 일부를 제한하거나
            중지할 수 있습니다.
          </p>
        </section>

        {/* 제7조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제7조 (회원의 의무)</h2>
          <p className='leading-relaxed text-gray-600'>
            1. 회원은 다음 행위를 하여서는 안 됩니다.
            <br />
            &nbsp;&nbsp;- 신청 또는 변경 시 허위내용의 등록
            <br />
            &nbsp;&nbsp;- 타인의 정보도용
            <br />
            &nbsp;&nbsp;- 회사가 게시한 정보의 변경
            <br />
            &nbsp;&nbsp;- 회사가 정한 정보 이외의 정보(컴퓨터 프로그램 등) 등의 송신 또는 게시
            <br />
            &nbsp;&nbsp;- 회사와 기타 제3자의 저작권 등 지적재산권에 대한 침해
            <br />
            &nbsp;&nbsp;- 회사 및 기타 제3자의 명예를 손상시키거나 업무를 방해하는 행위
            <br />
            &nbsp;&nbsp;- 외설 또는 폭력적인 메시지, 화상, 음성, 기타 공서양속에 반하는 정보를
            서비스에 공개 또는 게시하는 행위
            <br />
            &nbsp;&nbsp;- 서비스를 영리목적으로 이용하는 행위
            <br />
            &nbsp;&nbsp;- 기타 불법적이거나 부당한 행위
            <br />
            <br />
            2. 회원은 관계법령, 본 약관의 규정, 이용안내 및 서비스와 관련하여 공지한 주의사항,
            회사가 통지하는 사항 등을 준수하여야 합니다.
          </p>
        </section>

        {/* 제8조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제8조 (공유 가계부 관리)</h2>
          <p className='leading-relaxed text-gray-600'>
            1. 회원은 자신이 생성한 가계부를 다른 회원과 공유할 수 있습니다.
            <br />
            2. 공유 가계부의 소유자(Owner)는 멤버 초대, 권한 설정, 가계부 삭제 등의 권한을
            가집니다.
            <br />
            3. 공유 가계부의 멤버는 소유자가 부여한 권한에 따라 가계부를 열람 및 수정할 수
            있습니다.
            <br />
            4. 회원이 공유 가계부에서 탈퇴하거나 제명될 경우, 해당 가계부에 대한 접근 권한을
            상실합니다.
            <br />
            5. 소유자가 가계부를 삭제할 경우, 모든 멤버의 데이터가 함께 삭제되며 복구할 수
            없습니다.
          </p>
        </section>

        {/* 제9조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제9조 (SMS 자동수집 기능)</h2>
          <p className='leading-relaxed text-gray-600'>
            1. SMS 자동수집 기능은 안드로이드 기기에서만 제공됩니다.
            <br />
            2. 본 기능 사용을 위해서는 회원의 명시적 동의 및 SMS 읽기 권한 허용이 필요합니다.
            <br />
            3. 수집된 SMS는 거래 정보 파싱 목적으로만 사용되며, 회사는 원본 SMS 내용을
            저장하지 않습니다.
            <br />
            4. 회원은 언제든지 설정에서 SMS 자동수집 기능을 비활성화할 수 있습니다.
          </p>
        </section>

        {/* 제10조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제10조 (개인정보보호)</h2>
          <p className='leading-relaxed text-gray-600'>
            회사는 관련 법령이 정하는 바에 따라 회원의 개인정보를 보호하기 위해 노력합니다.
            개인정보의 보호 및 이용에 대해서는 관련 법령 및 회사의 개인정보처리방침이
            적용됩니다.
          </p>
        </section>

        {/* 제11조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제11조 (회사의 의무)</h2>
          <p className='leading-relaxed text-gray-600'>
            1. 회사는 법령과 본 약관이 금지하거나 공서양속에 반하는 행위를 하지 않으며, 본
            약관이 정하는 바에 따라 지속적이고 안정적으로 서비스를 제공하는 데 최선을 다하여야
            합니다.
            <br />
            2. 회사는 이용자가 안전하게 서비스를 이용할 수 있도록 이용자의 개인정보 보호를
            위한 보안시스템을 구축합니다.
            <br />
            3. 회사는 서비스 이용과 관련하여 이용자로부터 제기된 의견이나 불만이 정당하다고
            인정될 경우 이를 처리하여야 합니다.
          </p>
        </section>

        {/* 제12조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>
            제12조 (저작권의 귀속 및 이용제한)
          </h2>
          <p className='leading-relaxed text-gray-600'>
            1. 회사가 작성한 저작물에 대한 저작권 기타 지적재산권은 회사에 귀속합니다.
            <br />
            2. 이용자는 서비스를 이용함으로써 얻은 정보 중 회사에게 지적재산권이 귀속된 정보를
            회사의 사전 승낙 없이 복제, 송신, 출판, 배포, 방송 기타 방법에 의하여 영리목적으로
            이용하거나 제3자에게 이용하게 하여서는 안 됩니다.
            <br />
            3. 회원이 서비스 내에 게시한 게시물의 저작권은 해당 게시물의 저작자에게
            귀속됩니다.
          </p>
        </section>

        {/* 제13조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제13조 (면책조항)</h2>
          <p className='leading-relaxed text-gray-600'>
            1. 회사는 천재지변, 전쟁, 기간통신사업자의 서비스 중지 및 기타 이에 준하는
            불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 대한 책임이
            면제됩니다.
            <br />
            2. 회사는 회원의 귀책사유로 인한 서비스 이용의 장애에 대하여 책임을 지지 않습니다.
            <br />
            3. 회사는 회원이 서비스를 이용하여 기대하는 수익을 얻지 못하거나 상실한 것에
            대하여 책임을 지지 않습니다.
            <br />
            4. 회사는 회원 상호간 또는 회원과 제3자 간에 서비스를 매개로 발생한 분쟁에 대해
            개입할 의무가 없으며 이로 인한 손해를 배상할 책임도 없습니다.
            <br />
            5. 회사는 무료로 제공하는 서비스와 관련하여 관련 법령에 특별한 규정이 없는 한
            책임을 지지 않습니다.
            <br />
            6. 회사는 공유 가계부 멤버 간 발생한 데이터 손실, 삭제, 수정 등에 대해 책임을 지지
            않습니다.
          </p>
        </section>

        {/* 제14조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제14조 (손해배상)</h2>
          <p className='leading-relaxed text-gray-600'>
            회사는 서비스의 이용과 관련하여 회원에게 발생한 손해 중 회사의 고의 또는 중과실에
            의한 경우에 한하여 배상할 책임이 있습니다.
          </p>
        </section>

        {/* 제15조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제15조 (분쟁의 해결)</h2>
          <p className='leading-relaxed text-gray-600'>
            1. 회사와 회원은 서비스와 관련하여 발생한 분쟁을 원만하게 해결하기 위하여 필요한
            모든 노력을 하여야 합니다.
            <br />
            2. 제1항의 규정에도 불구하고 분쟁으로 인하여 소송이 제기될 경우 소송은 회사의 본사
            소재지를 관할하는 법원을 관할 법원으로 합니다.
          </p>
        </section>

        {/* 제16조 */}
        <section className='mb-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>제16조 (준거법)</h2>
          <p className='leading-relaxed text-gray-600'>
            본 약관은 대한민국 법률에 따라 규율되고 해석됩니다.
          </p>
        </section>

        {/* 부칙 */}
        <section className='mb-8 border-t border-gray-200 pt-8'>
          <h2 className='mb-3 text-xl font-bold text-gray-900'>부칙</h2>
          <p className='mb-4 leading-relaxed text-gray-600'>
            본 약관은 2026년 2월 6일부터 시행됩니다.
          </p>
          <div className='rounded-lg bg-gray-50 p-4'>
            <p className='font-semibold text-gray-800'>회사 정보</p>
            <p className='mt-1 text-sm text-gray-600'>서비스명: 우생가계부</p>
            <p className='text-sm text-gray-600'>운영자: [운영자명 입력 필요]</p>
            <p className='text-sm text-gray-600'>이메일: [고객지원 이메일 입력 필요]</p>
          </div>
          <p className='mt-4 text-sm text-gray-500'>
            본 약관에 대한 문의사항이 있으시면 위 이메일로 연락 주시기 바랍니다.
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
