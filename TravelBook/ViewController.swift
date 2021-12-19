//
//  ViewController.swift
//  TravelBook
//
//  Created by Birkan Pusa on 17.12.2021.
//

import UIKit
import MapKit
//konum alabilmek için corelocation
import CoreLocation
//veritabanı için
import CoreData

//Sınıfları viewcontroller'e tanımlıyoruz
class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    //değişkenler tanımlandı
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongtitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongtitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        locationManager.delegate = self
        // en iyi konumu al dedik
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //izin istedik
        locationManager.requestWhenInUseAuthorization()
        //konumu güncellemeye başladık
        locationManager.startUpdatingLocation()
        
        navigationItem.title = "Detay"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Kaydet", style: .plain, target: self, action: #selector(saveButtonClicked))

        //kullanmadığım butonu gizledim
        saveButton.isHidden = true
        
        
        //klavye kapama
        let hideKeyboardRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(hideKeyboardRecognizer)
        
        //uzun dokunulduğu zaman devreye girer
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        // basılı tutma süresi
        gestureRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        
        //eğer veri geliyorsa gösterilmesi gereken
        if selectedTitle != "" {
            
            //girilen veriyi açınca savebutton'u kapadım
            saveButton.isHidden = true
            navigationItem.rightBarButtonItem?.isEnabled = false
            //coredata
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                        }
                        
                        if let subTitle = result.value(forKey: "subtitle") as? String {
                            annotationSubTitle = subTitle
                        }
                        
                        if let latitude = result.value(forKey: "latitude") as? Double {
                          annotationLatitude = latitude
                        }
                        
                        if let longtitude = result.value(forKey: "longtitude") as? Double {
                           annotationLongtitude = longtitude
                            
                            let annotation = MKPointAnnotation()
                            annotation.title = annotationTitle
                            annotation.subtitle = annotationSubTitle
                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongtitude)
                            annotation.coordinate = coordinate
                            
                            mapView.addAnnotation(annotation)
                            nameText.text = annotationTitle
                            commentText.text = annotationSubTitle
                            
                            locationManager.stopUpdatingLocation()
                            
                            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            let region = MKCoordinateRegion(center: coordinate, span: span)
                            mapView.setRegion(region, animated: true)
                            
                            
                        }
                    }
                }
            } catch {
                
            }
            
        } else {
            //add new data
        }
        
    }
    
    //klavye kapama fonksiyonu
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    //Uzun dokunulduğu zaman ne olacak
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            //Nereye dokunulduğunu al
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            //dokunulan yeri koordinata çevir
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            
            //değişkenlere koordinatları gönderdik
            chosenLatitude = touchedCoordinates.latitude
            chosenLongtitude = touchedCoordinates.longitude
            
            //pin oluştur
            let annotation = MKPointAnnotation()
            //dokunulan coordinati al
            annotation.coordinate = touchedCoordinates
            //Title
            annotation.title = nameText.text
            //subtitle
            annotation.subtitle = commentText.text
            //ekliyoruz
            self.mapView.addAnnotation(annotation)
        }
        
    }
    
    //konumu mapte göstermek için gerekli fonksiyon
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
        //koordinatı diziden aldık
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //zoom seviyesi ayarlama
        let span = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: false)
        } else {
            //
        }
        
    }
    
    //pini özelleştirmek, haritayı açıp pine gitmek
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        //Kullanıcının yerini pinle göstermek istemiyoruz
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    //navigasyon için tıklandığını anlamak
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedTitle != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongtitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        //navigasyonu açabilmek için map item gerekli, map item için de placemark objesi gerekli reversegeocodelocation metoduyla alıyoruz
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        //hangi modda açacağımızı belirttikten sonra navigasyon açılabilir
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                        
                        
                        
                    }
                }
                
            }
        }
        
    }
    
    
    //@IBAction (_ sender: Any)
    @objc func saveButtonClicked() {
        
        //nametextten gelen veri doluysa işlem yap yoksa yapma dedik
        if nameText.text != "" {
            let appDeletagate = UIApplication.shared.delegate as! AppDelegate
            let context = appDeletagate.persistentContainer.viewContext
            
            let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
            
            newPlace.setValue(nameText.text, forKey: "title")
            newPlace.setValue(commentText.text, forKey: "subtitle")
            newPlace.setValue(chosenLatitude, forKey: "latitude")
            newPlace.setValue(chosenLongtitude, forKey: "longtitude")
            newPlace.setValue(UUID(), forKey: "id")
            
            do{
                try context.save()
                print("success")
                
            } catch {
                print("failed")
            }
            
            // diğer sayfaya bildirim gönderdik, bu bildirim gidince veriyi yenile diyeceğiz
                    NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "newData"), object: nil)
                    self.navigationController?.popViewController(animated: true)
        print("oldu")
        } else {
            //veri girmeyince uyarı mesajı gönder
            let alert = UIAlertController(title: "Hata", message: "Ad girmediniz", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            print("olmadı")
        }
        

        
    }
    
    
    

}

