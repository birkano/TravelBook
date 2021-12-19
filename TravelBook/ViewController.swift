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
        
        
        //klavye kapama
        let hideKeyboardRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        mapView.addGestureRecognizer(hideKeyboardRecognizer)

        //uzun dokunulduğu zaman devreye girer
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        // basılı tutma süresi
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        //eğer veri geliyorsa gösterilmesi gereken
        if selectedTitle != "" {
            
            //girilen veriyi açınca savebutton'u kapadım
            saveButton.isHidden = true

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
        mapView.endEditing(true)
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
        //koordinatı diziden aldık
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //zoom seviyesi ayarlama
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
        
    }
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
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
        
    }
    
    

}

