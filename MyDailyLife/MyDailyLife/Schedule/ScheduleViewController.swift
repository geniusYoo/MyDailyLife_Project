//
//  ScheduleViewController.swift
//  FloatingActionButton
//
//  Created by 김진웅 on 2022/08/13.
//

import UIKit
import RealmSwift

class ScheduleViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var applyButton: UIButton!
    
    @IBOutlet weak var memoTextField: UITextField!

    @IBOutlet weak var allDayToggle: UISwitch!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var exitDatePicker: UIDatePicker!
    
    private var allDay:Bool = false
    private var scheduleTitle: String!
    private var startDate: Date!
    private var exitDate: Date!
    
    let localRealm = try! Realm() // Realm 데이터를 저장할 localRealm 상수 선언

    override func viewDidLoad() {
        super.viewDidLoad()
        defaultDate()
        titleTextField.delegate = self
        memoTextField.delegate = self
        searchDirectory()
    }
    
    // Realm defaults가 들어있는 디렉토리를 찾는 코드, 디버거로 멈춰서 찾으면 됨
    private func searchDirectory() {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        print(documentsDirectory)
        print("Realm is located at:", localRealm.configuration.fileURL!)
    }
    
    // 입력이 끝나고 화면 빈 곳을 터치했을 때 키보드가 사라지게끔..
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.titleTextField.resignFirstResponder()
        self.memoTextField.resignFirstResponder()
    }
    
    // 기본 날짜 지정 (nil값 체크 안되게..)
    private func defaultDate() {
        startDatePicker.date = Date()
        exitDatePicker.date = Date()+3600
        startDate = startDatePicker.date
        exitDate = exitDatePicker.date
    }
    
    // 하루종일 토글 버튼 동작시 호출되는 함수
    @IBAction func allDayToggleTapped(_ sender: UISwitch) {
        if allDayToggle.isOn {
            self.setAllDay(allDay: true, dateMode: .date)
        } else {
            self.setAllDay(allDay: false, dateMode: .dateAndTime)
        }
    }
    private func setAllDay(allDay:Bool, dateMode:UIDatePicker.Mode) {
        self.allDay = allDay
        DispatchQueue.main.async {
            self.startDatePicker.datePickerMode = dateMode
            self.exitDatePicker.datePickerMode = dateMode
        }
    }
    
    // 시작 날짜 지정 + startDate를 Date변수로 바꿔서 코드 리팩토링
    @IBAction func changeStartDate(_ sender: UIDatePicker) {
        let datePickerView = sender
        startDate = datePickerView.date
//        exitDatePicker.date = startDate + 3600
    }
    
    // 종료 날짜 지정 + exitDate를 Date변수로 바꿔서 코드 리팩토링
    @IBAction func changeExitDate(_ sender: UIDatePicker) {
        let datePickerView = sender
        exitDate = datePickerView.date
    }
    
    // all Day가 true 일때 startDate는 00시, exitDate는 23시 59분
    private func checkAllDayIsTrue(_ startDate: inout Date?, _ exitDate: inout Date?,_ allDay:inout Bool) {
        let date = Calendar.current.date(bySettingHour: 9, minute: 00, second: 00, of: startDate!)
        startDate = date
        startDate! -= 86400
        exitDate! = startDate! + 86399
    }
    
    //
    private func UTCtoKST(_ startDate: inout Date?, _ exitDate: inout Date?) {
            let timeZone = TimeZone.autoupdatingCurrent
            let secondsFromGMT = timeZone.secondsFromGMT(for: startDate!)
            startDate = startDate?.addingTimeInterval(TimeInterval(secondsFromGMT))
            let secondsFromGMT2 = timeZone.secondsFromGMT(for: exitDate!)
            exitDate = exitDate?.addingTimeInterval(TimeInterval(secondsFromGMT2))
    }
    
    @IBAction func applyButtonPressed(_ sender: UIButton) {
        UTCtoKST(&startDate, &exitDate)
        
        if allDay {
            checkAllDayIsTrue(&startDate, &exitDate, &allDay)
        }
        
        if (exitDate < startDate) {
            let alert = UIAlertController(title: "Warning", message: "종료 날짜는 시작 날짜보다 빠를 수 없습니다.", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                        
            }
            alert.addAction(okAction)
            present(alert, animated: false, completion: nil)
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when){
              // your code with delay
              alert.dismiss(animated: true, completion: nil)
            }
        }
        else {
            // 지금 사용자가 화면에서 입력한 것을 Schedule 객체로 만들어 task를 만든다
            let task = Schedule(content: titleTextField.text!, startDate: startDate, endDate: exitDate, memo: memoTextField.text!, allDay: allDay)
            
            // 만든 task를 localRealm에 저장
            try! localRealm.write {
                localRealm.add(task)
            }
            
            self.dismiss(animated: true, completion: nil) // 모달 닫는 동작
        }
    }
}


extension ScheduleViewController:UITextFieldDelegate {
    // 자동적으로 키보드가 올라오게끔
    override func viewWillAppear(_ animated: Bool) {
        self.titleTextField.becomeFirstResponder()
    }
    
    // 키보드에서 done이 눌렸을 때 키보드가 사라지게 함
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        titleTextField.endEditing(true)
        memoTextField.endEditing(true)
        return true
    }
}

